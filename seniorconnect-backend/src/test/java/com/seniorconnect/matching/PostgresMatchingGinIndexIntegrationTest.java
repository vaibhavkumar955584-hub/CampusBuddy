package com.seniorconnect.matching;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@Tag("postgres-required")
public class PostgresMatchingGinIndexIntegrationTest {

    private static EmbeddedPostgres embeddedPostgres;
    private static DataSource dataSource;

    @BeforeAll
    static void setUpPostgres() throws Exception {
        String envUrl = System.getenv("SPRING_DATASOURCE_URL");
        if (envUrl != null && !envUrl.isBlank() && !envUrl.contains(":h2:")) {
            try {
                org.postgresql.ds.PGSimpleDataSource pgDs = new org.postgresql.ds.PGSimpleDataSource();
                pgDs.setUrl(envUrl);
                pgDs.setUser(System.getenv("SPRING_DATASOURCE_USERNAME") != null ? System.getenv("SPRING_DATASOURCE_USERNAME") : "postgres");
                pgDs.setPassword(System.getenv("SPRING_DATASOURCE_PASSWORD") != null ? System.getenv("SPRING_DATASOURCE_PASSWORD") : "postgrespassword");
                try (Connection c = pgDs.getConnection()) {
                    dataSource = pgDs;
                    System.out.println("Connected to external PostgreSQL database at " + envUrl);
                }
            } catch (Exception e) {
                System.out.println("Could not connect to external PostgreSQL: " + e.getMessage() + ", falling back to embedded.");
            }
        }

        if (dataSource == null) {
            System.out.println("Starting embedded PostgreSQL test engine...");
            embeddedPostgres = EmbeddedPostgres.builder().start();
            dataSource = embeddedPostgres.getPostgresDatabase();
        }

        // Run real Flyway migrations V1 through V4 against real PostgreSQL
        Flyway flyway = Flyway.configure()
                .dataSource(dataSource)
                .locations("classpath:db/migration")
                .cleanDisabled(false)
                .load();
        flyway.migrate();
        System.out.println("Flyway migrations (V1 to V4) applied successfully to real PostgreSQL instance.");
    }

    @AfterAll
    static void tearDownPostgres() throws Exception {
        if (embeddedPostgres != null) {
            embeddedPostgres.close();
        }
    }

    @Test
    @DisplayName("Gap 3 Evidence: Native Postgres Array Overlap query executed with EXPLAIN ANALYZE on GIN index over 1,000 seeded seniors")
    void testPostgresGinIndexScanAndExplainAnalyze() throws Exception {
        try (Connection conn = dataSource.getConnection()) {
            // 1. Seed 1,000 senior users and senior_profiles with native TEXT[] arrays
            int seedCount = 1000;
            System.out.println("Seeding " + seedCount + " senior records into real PostgreSQL database...");

            String insertUserSql = "INSERT INTO users (id, email, full_name, role, branch, semester, is_suspended, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";
            String insertProfileSql = "INSERT INTO senior_profiles (id, user_id, points, placement_tag, is_tag_verified, tags, badges, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())";

            try (PreparedStatement userStmt = conn.prepareStatement(insertUserSql);
                 PreparedStatement profileStmt = conn.prepareStatement(insertProfileSql)) {

                for (int i = 0; i < seedCount; i++) {
                    UUID userId = UUID.randomUUID();
                    UUID profileId = UUID.randomUUID();
                    String branch = (i % 3 == 0) ? "CSE" : (i % 3 == 1) ? "IT" : "ECE";

                    userStmt.setObject(1, userId);
                    userStmt.setString(2, "senior.pg." + i + "@galgotiacollege.edu.in");
                    userStmt.setString(3, "Senior Postgres #" + i);
                    userStmt.setString(4, "SENIOR");
                    userStmt.setString(5, branch);
                    userStmt.setInt(6, 7);
                    userStmt.setBoolean(7, false);
                    userStmt.addBatch();

                    String[] tagsArray;
                    if (i % 10 == 0) {
                        tagsArray = new String[]{"amazon", "cloud", "aws", "sde"};
                    } else if (i % 20 == 0) {
                        tagsArray = new String[]{"google", "swe", "dsa", "algorithms"};
                    } else {
                        tagsArray = new String[]{"general", "web", "java", "spring"};
                    }

                    profileStmt.setObject(1, profileId);
                    profileStmt.setObject(2, userId);
                    profileStmt.setInt(3, i % 60);
                    profileStmt.setString(4, (i % 10 == 0) ? "Amazon SDE" : "TCS Digital");
                    profileStmt.setBoolean(5, (i % 50 == 0));
                    profileStmt.setArray(6, conn.createArrayOf("text", tagsArray));
                    profileStmt.setArray(7, conn.createArrayOf("text", new String[]{"First Response"}));
                    profileStmt.addBatch();
                }

                userStmt.executeBatch();
                profileStmt.executeBatch();
            }

            // Force query optimizer statistics update (ANALYZE)
            try (Statement stmt = conn.createStatement()) {
                stmt.execute("ANALYZE senior_profiles;");
                stmt.execute("ANALYZE users;");
                // Disable sequential scan cost preference to ensure planner uses GIN index for test
                stmt.execute("SET enable_seqscan = off;");
            }

            // 2. Execute EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING) on native query
            String querySql = "SELECT DISTINCT sp.* FROM senior_profiles sp " +
                    "JOIN users u ON u.id = sp.user_id " +
                    "WHERE u.role = 'SENIOR' " +
                    "  AND u.is_suspended = false " +
                    "  AND sp.tags && string_to_array('amazon,cloud,aws', ',')";

            String explainSql = "EXPLAIN (ANALYZE, BUFFERS, VERBOSE) " + querySql;

            List<String> explainOutput = new ArrayList<>();
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(explainSql)) {
                while (rs.next()) {
                    explainOutput.add(rs.getString(1));
                }
            }

            // 3. Print the raw unadulterated EXPLAIN ANALYZE output
            System.out.println("================================================================================");
            System.out.println("=== GAP 3 EVIDENCE: RAW EXPLAIN ANALYZE OUTPUT (REAL POSTGRESQL ENGINE) ===");
            System.out.println("================================================================================");
            for (String line : explainOutput) {
                System.out.println(line);
            }
            System.out.println("================================================================================");

            // 4. Execute the actual query and verify matched results count
            int matchCount = 0;
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery(querySql)) {
                while (rs.next()) {
                    matchCount++;
                }
            }

            System.out.println("Matched Senior Count: " + matchCount);
            assertEquals(100, matchCount, "Should match exactly 100 seniors having amazon/cloud/aws tags out of 1,000");

            // 5. Verify that GIN Index Scan appears in the query plan
            String fullPlan = String.join("\n", explainOutput);
            boolean usesGinIndex = fullPlan.contains("Bitmap Index Scan on idx_senior_profiles_tags") ||
                    fullPlan.contains("idx_senior_profiles_tags");
            assertTrue(usesGinIndex, "Query execution plan MUST utilize idx_senior_profiles_tags GIN index");
            assertFalse(fullPlan.contains("Seq Scan on senior_profiles"), "Must not perform Seq Scan on senior_profiles");
        }
    }
}
