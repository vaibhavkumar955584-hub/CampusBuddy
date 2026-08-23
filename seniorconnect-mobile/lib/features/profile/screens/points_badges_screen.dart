import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';

class BadgeItem {
  final String title;
  final String description;
  final IconData icon;
  final int pointsThreshold;
  final bool requiresVerification;

  const BadgeItem({
    required this.title,
    required this.description,
    required this.icon,
    this.pointsThreshold = 0,
    this.requiresVerification = false,
  });
}

class PointsBadgesScreen extends StatefulWidget {
  const PointsBadgesScreen({super.key});

  @override
  State<PointsBadgesScreen> createState() => _PointsBadgesScreenState();
}

class _PointsBadgesScreenState extends State<PointsBadgesScreen> {
  final ApiClient _apiClient = ApiClient();

  int _points = 0;
  String? _placementTag;
  bool _isTagVerified = false;
  List<String> _earnedBadges = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<BadgeItem> _availableBadges = [
    BadgeItem(
      title: 'First Response',
      description: 'Answered your first junior mentorship question.',
      icon: Icons.emoji_events_rounded,
      pointsThreshold: 1,
    ),
    BadgeItem(
      title: '10 Helped',
      description: 'Reached 10 mentorship points by guiding students.',
      icon: Icons.star_rounded,
      pointsThreshold: 10,
    ),
    BadgeItem(
      title: 'Verified Mentor',
      description: 'Company/Placement credentials verified by admin.',
      icon: Icons.verified_user_rounded,
      requiresVerification: true,
    ),
    BadgeItem(
      title: 'Top Contributor',
      description: 'Achieved 50+ points in campus mentorship community.',
      icon: Icons.military_tech_rounded,
      pointsThreshold: 50,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  String? _verificationStatus;
  String? _rejectionReason;

  Future<void> _fetchProfile() async {
    final user = _apiClient.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(ApiConstants.profile(user.id));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _points = data['points'] ?? 0;
          _placementTag = data['placementTag'];
          _isTagVerified = data['isTagVerified'] ?? false;
          _earnedBadges = List<String>.from(data['badges'] ?? []);
        });
      } else {
        setState(() => _errorMessage = 'Failed to load points data');
      }

      // Fetch verification request status
      final vRes = await _apiClient.get(ApiConstants.myVerificationRequests);
      if (vRes.statusCode == 200) {
        final list = jsonDecode(vRes.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final latest = list.first;
          setState(() {
            _verificationStatus = latest['status'];
            _rejectionReason = latest['rejectionReason'];
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error loading profile');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiClient.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Points & Badges',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.onSurface),
        ),
      ),
      body: _isLoading
          ? const SkeletonFeedList(count: 3)
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                      ),
                    ],
                    // Points Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [AppTheme.ambientShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                child: Text(
                                  user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'S',
                                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Senior Mentor',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      user?.branch ?? 'Engineering Mentor',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isTagVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('VERIFIED', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TOTAL POINTS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_points pts',
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('BADGES UNLOCKED', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_earnedBadges.length} / ${_availableBadges.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_placementTag != null && _placementTag!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Role: $_placementTag',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tag Verification Status Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isTagVerified
                                    ? Icons.verified
                                    : (_verificationStatus == 'PENDING'
                                        ? Icons.hourglass_top_rounded
                                        : (_verificationStatus == 'REJECTED' ? Icons.cancel_rounded : Icons.shield_outlined)),
                                size: 20,
                                color: _isTagVerified
                                    ? AppTheme.success
                                    : (_verificationStatus == 'PENDING'
                                        ? Colors.orange
                                        : (_verificationStatus == 'REJECTED' ? AppTheme.error : AppTheme.primary)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Achievement Tag Verification',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isTagVerified
                                      ? AppTheme.success.withValues(alpha: 0.12)
                                      : (_verificationStatus == 'PENDING'
                                          ? Colors.orange.withValues(alpha: 0.12)
                                          : (_verificationStatus == 'REJECTED'
                                              ? AppTheme.error.withValues(alpha: 0.12)
                                              : AppTheme.primary.withValues(alpha: 0.12))),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _isTagVerified
                                      ? 'Verified'
                                      : (_verificationStatus == 'PENDING'
                                          ? 'Pending Review'
                                          : (_verificationStatus == 'REJECTED' ? 'Not Verified' : 'Unverified')),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isTagVerified
                                        ? AppTheme.success
                                        : (_verificationStatus == 'PENDING'
                                            ? Colors.orange
                                            : (_verificationStatus == 'REJECTED' ? AppTheme.error : AppTheme.primary)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isTagVerified
                                ? 'Your achievement tag "${_placementTag ?? "Placed"}" is officially verified by campus administration.'
                                : (_verificationStatus == 'PENDING'
                                    ? 'Your proof is under review by campus administrators. OCR-assisted triage in progress.'
                                    : (_verificationStatus == 'REJECTED'
                                        ? 'Verification was rejected: ${_rejectionReason ?? "Document not clear"}. You may re-upload valid proof.'
                                        : 'Upload your official offer letter or certificate screenshot for admin verification.')),
                            style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.4),
                          ),
                          if (!_isTagVerified && _verificationStatus != 'PENDING') ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select offer letter or certificate image (max 5MB)')),
                                );
                              },
                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                              label: Text(_verificationStatus == 'REJECTED' ? 'Re-upload Proof' : 'Upload Proof Screenshot'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(color: AppTheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Achievement Badges',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Badges are automatically awarded as you answer queries and help juniors.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ..._availableBadges.map((b) => _buildBadgeCard(b)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadgeCard(BadgeItem badge) {
    final isEarned = _earnedBadges.contains(badge.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned ? AppTheme.surfaceContainerLowest : AppTheme.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEarned ? AppTheme.primaryContainer.withValues(alpha: 0.5) : AppTheme.cardBorder,
          width: isEarned ? 1.5 : 1,
        ),
        boxShadow: isEarned ? const [AppTheme.ambientShadow] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEarned ? AppTheme.primaryContainer.withValues(alpha: 0.15) : AppTheme.outlineVariant.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              badge.icon,
              size: 26,
              color: isEarned ? AppTheme.primary : AppTheme.outline,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      badge.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isEarned ? AppTheme.onSurface : AppTheme.outline,
                      ),
                    ),
                    const Spacer(),
                    if (isEarned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('UNLOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('LOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.outline)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEarned ? AppTheme.onSurfaceVariant : AppTheme.outline,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
