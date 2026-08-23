package com.seniorconnect.security;

import io.zonky.test.db.postgres.embedded.EmbeddedPostgres;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.postgresql.ds.PGSimpleDataSource;

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
public class RlsAppRoleImmutabilityIntegrationTest {

    private static EmbeddedPostgres embeddedPostgres;
    private static DataSource adminDataSource;
    private static PGSimpleDataSource appDataSource;

    @BeforeAll
    static void setUpPostgres() throws Exception {
        String envUrl = System.getenv("SPRING_DATASOURCE_URL");
        if (envUrl != null && !envUrl.isBlank() && !envUrl.contains(":h2:")) {
            try {
                PGSimpleDataSource pgDs = new PGSimpleDataSource();
                pgDs.setUrl(envUrl);
                pgDs.setUser(System.getenv("SPRING_DATASOURCE_USERNAME") != null ? System.getenv("SPRING_DATASOURCE_USERNAME") : "postgres");
                pgDs.setPassword(System.getenv("SPRING_DATASOURCE_PASSWORD") != null ? System.getenv("SPRING_DATASOURCE_PASSWORD") : "postgrespassword");
                try (Connection c = pgDs.getConnection()) {
                    adminDataSource = pgDs;
                }
            } catch (Exception ignored) {
            }
        }

        if (adminDataSource == null) {
            embeddedPostgres = EmbeddedPostgres.builder().start();
            adminDataSource = embeddedPostgres.getPostgresDatabase();
        }

        // Run Flyway migrations V1 through V5 as superuser / migration runner
        Flyway flyway = Flyway.configure()
                .dataSource(adminDataSource)
                .locations("classpath:db/migration")
                .cleanDisabled(false)
                .load();
        flyway.migrate();

        // Configure connection pool / datasource for dedicated runtime role: seniorconnect_app
        appDataSource = new PGSimpleDataSource();
        if (embeddedPostgres != null) {
            appDataSource.setPortNumbers(new int[]{embeddedPostgres.getPort()});
            appDataSource.setDatabaseName("postgres");
            appDataSource.setServerNames(new String[]{"localhost"});
        } else {
            appDataSource.setUrl(envUrl);
        }
        appDataSource.setUser("seniorconnect_app");
        appDataSource.setPassword("seniorconnect_app_secret");
    }

    @AfterAll
    static void tearDownPostgres() throws Exception {
        if (embeddedPostgres != null) {
            embeddedPostgres.close();
        }
    }

    @Test
    @DisplayName("Gap 2 Evidence: RLS enforced and audit_logs strictly immutable when connecting specifically as seniorconnect_app role")
    void testRlsAndAuditLogImmutabilityUnderSeniorConnectAppRole() throws Exception {
        UUID juniorAId = UUID.randomUUID();
        UUID juniorBId = UUID.randomUUID();
        UUID seniorId = UUID.randomUUID();

        // 1. Seed initial records using admin connection
        try (Connection adminConn = adminDataSource.getConnection()) {
            try (PreparedStatement ps = adminConn.prepareStatement(
                    "INSERT INTO users (id, email, full_name, role, branch, semester, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())")) {
                // Junior A
                ps.setObject(1, juniorAId);
                ps.setString(2, "juniorA.rls@galgotiacollege.edu.in");
                ps.setString(3, "Junior A");
                ps.setString(4, "JUNIOR");
                ps.setString(5, "CSE");
                ps.setInt(6, 3);
                ps.addBatch();

                // Junior B
                ps.setObject(1, juniorBId);
                ps.setString(2, "juniorB.rls@galgotiacollege.edu.in");
                ps.setString(3, "Junior B");
                ps.setString(4, "JUNIOR");
                ps.setString(5, "IT");
                ps.setInt(6, 3);
                ps.addBatch();

                // Senior
                ps.setObject(1, seniorId);
                ps.setString(2, "senior.rls@galgotiacollege.edu.in");
                ps.setString(3, "Senior Mentor");
                ps.setString(4, "SENIOR");
                ps.setString(5, "CSE");
                ps.setInt(6, 7);
                ps.addBatch();

                ps.executeBatch();
            }

            // Insert parent queries for Junior A and Junior B
            UUID queryAId = UUID.randomUUID();
            UUID queryBId = UUID.randomUUID();
            try (PreparedStatement ps = adminConn.prepareStatement(
                    "INSERT INTO queries (id, junior_id, title, content, tags, status, created_at) VALUES (?, ?, ?, ?, ?, 'OPEN', NOW())")) {
                ps.setObject(1, queryAId);
                ps.setObject(2, juniorAId);
                ps.setString(3, "DSA Question");
                ps.setString(4, "Junior A question on DSA");
                ps.setArray(5, adminConn.createArrayOf("TEXT", new String[]{"DSA", "Java"}));
                ps.addBatch();

                ps.setObject(1, queryBId);
                ps.setObject(2, juniorBId);
                ps.setString(3, "DBMS Question");
                ps.setString(4, "Junior B private question");
                ps.setArray(5, adminConn.createArrayOf("TEXT", new String[]{"DBMS"}));
                ps.addBatch();

                ps.executeBatch();
            }

            // Insert Reveal Request for Junior A and Reveal Request for Junior B
            UUID revealAId = UUID.randomUUID();
            UUID revealBId = UUID.randomUUID();
            try (PreparedStatement ps = adminConn.prepareStatement(
                    "INSERT INTO reveal_requests (id, query_id, junior_id, senior_id, status, created_at) VALUES (?, ?, ?, ?, 'PENDING', NOW())")) {
                ps.setObject(1, revealAId);
                ps.setObject(2, queryAId);
                ps.setObject(3, juniorAId);
                ps.setObject(4, seniorId);
                ps.addBatch();

                ps.setObject(1, revealBId);
                ps.setObject(2, queryBId);
                ps.setObject(3, juniorBId);
                ps.setObject(4, seniorId);
                ps.addBatch();

                ps.executeBatch();
            }

            // Insert initial Audit Log
            try (PreparedStatement ps = adminConn.prepareStatement(
                    "INSERT INTO audit_logs (id, event_type, actor_id, ip_address, details, created_at) VALUES (?, ?, ?, ?, ?, NOW())")) {
                ps.setObject(1, UUID.randomUUID());
                ps.setString(2, "SYSTEM_INIT");
                ps.setObject(3, juniorAId);
                ps.setString(4, "127.0.0.1");
                ps.setString(5, "Initial secure baseline entry");
                ps.executeUpdate();
            }
        }

        // 2. Connect strictly as runtime application role: seniorconnect_app
        try (Connection appConn = appDataSource.getConnection()) {
            // Confirm active DB user is 'seniorconnect_app'
            try (Statement st = appConn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT current_user, session_user")) {
                assertTrue(rs.next());
                String currentUser = rs.getString(1);
                assertEquals("seniorconnect_app", currentUser, "Active database connection must be seniorconnect_app");
                System.out.println("Active PostgreSQL Role verified: " + currentUser);
            }

            // 3. Test Row-Level Security: Set session to Junior A and query reveal_requests
            try (PreparedStatement ps = appConn.prepareStatement("SELECT set_config('app.current_user_id', ?, false)")) {
                ps.setString(1, juniorAId.toString());
                ps.execute();
            }
            try (PreparedStatement ps = appConn.prepareStatement("SELECT set_config('app.current_user_role', 'JUNIOR', false)")) {
                ps.execute();
            }

            List<UUID> visibleReveals = new ArrayList<>();
            try (Statement st = appConn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT id, junior_id FROM reveal_requests")) {
                while (rs.next()) {
                    visibleReveals.add((UUID) rs.getObject("junior_id"));
                }
            }

            // RLS assertion: ONLY Junior A's row is visible; Junior B's row is strictly hidden
            assertEquals(1, visibleReveals.size(), "RLS must filter out private reveal requests of other users");
            assertEquals(juniorAId, visibleReveals.get(0), "Visible reveal request must strictly belong to Junior A");
            System.out.println("RLS Enforcement Confirmed: Junior A only sees their own row (" + visibleReveals.size() + " returned)");

            // 4. Test Audit Log Immutability: Attempt UPDATE on audit_logs as seniorconnect_app
            Exception updateException = null;
            try (Statement st = appConn.createStatement()) {
                st.executeUpdate("UPDATE audit_logs SET details = 'TAMPERED_ENTRY'");
            } catch (Exception e) {
                updateException = e;
            }
            assertNotNull(updateException, "Database must reject UPDATE on audit_logs for seniorconnect_app role");
            System.out.println("Audit Log UPDATE Rejection Confirmed: " + updateException.getMessage());

            // 5. Test Audit Log Immutability: Attempt DELETE on audit_logs as seniorconnect_app
            Exception deleteException = null;
            try (Statement st = appConn.createStatement()) {
                st.executeUpdate("DELETE FROM audit_logs");
            } catch (Exception e) {
                deleteException = e;
            }
            assertNotNull(deleteException, "Database must reject DELETE on audit_logs for seniorconnect_app role");
            System.out.println("Audit Log DELETE Rejection Confirmed: " + deleteException.getMessage());

            // Confirm audit_logs data remains intact
            try (Statement st = appConn.createStatement();
                 ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM audit_logs")) {
                assertTrue(rs.next());
                assertTrue(rs.getInt(1) >= 1, "Audit logs must remain immutable and intact");
            }
        }
    }
}
