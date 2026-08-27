import '../models/user_model.dart';

class UserRoleHelper {
  /// Evaluates whether the current student is a Senior Mentor (3rd Year, 4th Year, Alumni)
  /// or a Junior Student (1st Year, 2nd Year).
  static bool isSenior({
    UserModel? appUser,
    String? email,
    String? yearOfStudy,
  }) {
    if (appUser != null && appUser.isSenior) return true;

    if (yearOfStudy != null && yearOfStudy.isNotEmpty) {
      if (yearOfStudy.contains('3') ||
          yearOfStudy.contains('4') ||
          yearOfStudy.toLowerCase().contains('alumni') ||
          yearOfStudy.toLowerCase().contains('senior')) {
        return true;
      }
      if (yearOfStudy.contains('1') || yearOfStudy.contains('2')) {
        return false;
      }
    }

    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first.toLowerCase();
      // Match roll pattern e.g. vaibhav.24gcebit052 or 24gcebit052
      final match = RegExp(r'(?:^|[._])(\d{2})').firstMatch(prefix);
      if (match != null) {
        final yearDigits = int.tryParse(match.group(1)!);
        if (yearDigits != null) {
          final admissionYear = 2000 + yearDigits;
          final now = DateTime.now();
          // e.g. in 2026: 2026 - 2024 = 2 (+1 for Aug+ academic cycle) = 3rd Year
          final academicYear = now.year - admissionYear + (now.month >= 8 ? 1 : 0);
          if (academicYear >= 3 || admissionYear <= 2024) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static String getRoleLabel(bool isSenior) {
    return isSenior ? 'Senior Mentor' : 'Junior Student';
  }

  static String extractBranch(String? email, [String? fallback]) {
    if (email == null) return fallback ?? 'Information Technology';
    final prefix = email.split('@').first.toLowerCase();
    const branchMap = {
      'bit': 'Information Technology',
      'it': 'Information Technology',
      'bcs': 'Computer Science & Engineering',
      'cse': 'Computer Science & Engineering',
      'bce': 'Electronics & Communication Engineering',
      'ece': 'Electronics & Communication Engineering',
      'bee': 'Electrical & Electronics Engineering',
      'eee': 'Electrical & Electronics Engineering',
      'bme': 'Mechanical Engineering',
      'me': 'Mechanical Engineering',
      'bcv': 'Civil Engineering',
      'ce': 'Civil Engineering',
      'bai': 'Artificial Intelligence & Machine Learning',
      'aiml': 'Artificial Intelligence & Machine Learning',
      'bds': 'Data Science',
      'ds': 'Data Science',
    };

    final match = RegExp(r'(?:gce)?([a-z]+)\d{2,4}').firstMatch(prefix);
    if (match != null) {
      final code = match.group(1)!.toLowerCase();
      if (branchMap.containsKey(code)) {
        return branchMap[code]!;
      }
    }
    return fallback ?? 'Information Technology';
  }
}
