class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Auth endpoints
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String refresh = '$baseUrl/auth/refresh';
  static const String logout = '$baseUrl/auth/logout';

  // Queries
  static const String queries = '$baseUrl/queries';

  // Reveals
  static const String reveals = '$baseUrl/reveals';

  // Moderation
  static const String moderation = '$baseUrl/moderation';

  // Profiles
  static const String profiles = '$baseUrl/profiles';
}
