/// DEPRECATION NOTICE:
/// Direct Firestore data layer has been completely decommissioned for queries,
/// responses, reveals, and user profiles in accordance with SeniorConnect security architecture.
///
/// All application operations must route through Spring Boot REST API (ApiClient)
/// which enforces PostgreSQL Row-Level Security (RLS), RS256 JWT cryptographic
/// validation, IDOR access controls, and transactional consent-gated reveals.
class FirestoreService {
  // Decommissioned - all data operations routed to Spring Boot backend REST API
}
