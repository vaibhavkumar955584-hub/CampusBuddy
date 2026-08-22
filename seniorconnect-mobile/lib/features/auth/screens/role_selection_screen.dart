import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'otp_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome to SeniorConnect',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "To get started, tell us how you'd like to use the app today.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 36),
              // Junior Card
              _buildRoleCard(
                context,
                title: "I'm a Junior",
                description: 'Looking for guidance, advice, and mentorship from experienced peers.',
                icon: Icons.school_rounded,
                iconBgColor: AppTheme.primaryContainer,
                role: 'JUNIOR',
              ),
              const SizedBox(height: 20),
              // Senior Card
              _buildRoleCard(
                context,
                title: "I'm a Senior",
                description: 'Here to share my experience, offer help, and guide others.',
                icon: Icons.volunteer_activism_rounded,
                iconBgColor: AppTheme.secondaryContainer,
                role: 'SENIOR',
              ),
              const Spacer(),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppTheme.surfaceTint),
                    const SizedBox(width: 6),
                    Text(
                      'Zero-Trust Institutional Security',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.outline,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required String role,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: const [AppTheme.ambientShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpLoginScreen(selectedRole: role),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
