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
  static String responses(String queryId) => '$queries/$queryId/responses';

  // Reveals
  static const String reveals = '$baseUrl/reveals';
  static const String pendingReveals = '$reveals/pending';
  static String respondReveal(String revealId) => '$reveals/$revealId/respond';

  // Moderation
  static const String moderation = '$baseUrl/moderation';

  // Profiles
  static const String profiles = '$baseUrl/profiles';
}
