import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnonymityBadge extends StatelessWidget {
  final bool isAnonymous;
  final String? studentName;
  final bool isCompact;

  const AnonymityBadge({
    super.key,
    required this.isAnonymous,
    this.studentName,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isAnonymous) {
      final bgColor = isDark ? const Color(0xFF332308) : const Color(0xFFFEF3C7);
      final fgColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 9,
          vertical: isCompact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded, size: isCompact ? 11 : 13, color: fgColor),
            const SizedBox(width: 4),
            Text(
              'Anonymous Junior',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ),
      );
    } else {
      final bgColor = isDark ? const Color(0xFF0F3E44) : const Color(0xFFDFF1F5);
      final fgColor = isDark ? AppTheme.darkPrimary : AppTheme.primary;
      final displayName = (studentName != null && studentName!.isNotEmpty) ? studentName! : 'Named Student';

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 9,
          vertical: isCompact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: isCompact ? 11 : 13, color: fgColor),
            const SizedBox(width: 4),
            Text(
              displayName,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ),
      );
    }
  }
}
