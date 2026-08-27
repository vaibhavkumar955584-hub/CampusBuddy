class ApiConstants {
  static const String baseUrl = 'http://localhost:8088/api/v1';

  // Auth endpoints
  static const String directLogin = '$baseUrl/auth/direct-login';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String refresh = '$baseUrl/auth/refresh';
  static const String logout = '$baseUrl/auth/logout';

  // Queries
  static const String queries = '$baseUrl/queries';
  static const String matchedQueries = '$queries/matched';
  static String responses(String queryId) => '$queries/$queryId/responses';

  // Reveals
  static const String reveals = '$baseUrl/reveals';
  static const String pendingReveals = '$reveals/pending';
  static String respondReveal(String revealId) => '$reveals/$revealId/respond';

  // Moderation & Reports
  static const String moderation = '$baseUrl/moderation';
  static const String reports = '$moderation/reports';

  // Profiles
  static const String profiles = '$baseUrl/profiles';
  static String profile(String userId) => '$profiles/$userId';

  // Verification & Proofs
  static const String verificationProof = '$profiles/verification/proof';
  static const String myVerificationRequests = '$profiles/verification/my-requests';

  // V2 AI Query Intelligence & 2-Stage Matching
  static const String analyzeQuery = '$queries/analyze';
  static String rankedMentors(String queryId) => '$baseUrl/matching/queries/$queryId/mentors';

  // V2 Mentorship Plans & Outcomes
  static const String mentorshipPlans = '$baseUrl/mentorships/plans';
  static const String myMentorshipPlans = '$mentorshipPlans/my';
  static String togglePlanTask(String planId, String taskId) => '$mentorshipPlans/$planId/tasks/$taskId/toggle';
  static const String submitOutcome = '$baseUrl/mentorships/outcomes';
  static const String verifiedOutcomes = '$baseUrl/mentorships/outcomes/verified';

  // V2 Privacy Level 3: 1-on-1 Direct Mentorship Sessions & Chat
  static const String myMentorshipSessions = '$baseUrl/mentorships/sessions/my';
  static String scheduleSession(String sessionId) => '$baseUrl/mentorships/sessions/$sessionId/schedule';
  static String sessionMessages(String sessionId) => '$baseUrl/mentorships/sessions/$sessionId/messages';

  // V2 Phase 4: Mentorship Analytics & Trust Reputation
  static String mentorAnalytics(String mentorId) => '$baseUrl/mentorships/mentors/$mentorId/analytics';
  static String submitSessionReview(String sessionId) => '$baseUrl/mentorships/sessions/$sessionId/reviews';
  static String mentorReviews(String mentorId) => '$baseUrl/mentorships/mentors/$mentorId/reviews';
  static const String campusOverview = '$baseUrl/mentorships/analytics/overview';
}
