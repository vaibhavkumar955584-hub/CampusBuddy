import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../queries/screens/query_detail_screen.dart';
import '../../reveal/screens/pending_reveals_screen.dart';

class NotificationItem {
  final String id;
  final String type; // NEW_RESPONSE, REVEAL_REQUEST, REVEAL_ACCEPTED, SYSTEM
  final String title;
  final String body;
  final String? resourceId;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.resourceId,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() => _isLoading = true);

    // Initial mock/received FCM state for in-app view
    final user = _apiClient.currentUser;
    final now = DateTime.now();

    final List<NotificationItem> sample = [];
    if (user != null && user.isJunior) {
      sample.addAll([
        NotificationItem(
          id: '1',
          type: 'NEW_RESPONSE',
          title: 'SeniorConnect Mentorship',
          body: 'A senior mentor has replied to your query. Open app to view.',
          resourceId: null,
          timestamp: now.subtract(const Duration(minutes: 15)),
        ),
        NotificationItem(
          id: '2',
          type: 'REVEAL_REQUEST',
          title: 'Identity Disclosure Request',
          body: 'A senior mentor requested to connect with you directly.',
          resourceId: null,
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
      ]);
    } else {
      sample.addAll([
        NotificationItem(
          id: '3',
          type: 'REVEAL_ACCEPTED',
          title: 'SeniorConnect Connection',
          body: 'A junior student accepted your connection request.',
          resourceId: null,
          timestamp: now.subtract(const Duration(hours: 1)),
        ),
        NotificationItem(
          id: '4',
          type: 'NEW_RESPONSE',
          title: 'New Matched Question',
          body: 'A new question was posted in your branch.',
          resourceId: null,
          timestamp: now.subtract(const Duration(days: 1)),
        ),
      ]);
    }

    setState(() {
      _notifications = sample;
      _isLoading = false;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final replies = _notifications.where((n) => n.type == 'NEW_RESPONSE').toList();
    final reveals = _notifications.where((n) => n.type == 'REVEAL_REQUEST' || n.type == 'REVEAL_ACCEPTED').toList();
    final system = _notifications.where((n) => n.type != 'NEW_RESPONSE' && n.type != 'REVEAL_REQUEST' && n.type != 'REVEAL_ACCEPTED').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.onSurface),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark All Read', style: TextStyle(fontSize: 13, color: AppTheme.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, index) => const SkeletonListTile(),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Notifications Yet',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You will receive push updates when mentors answer or connection requests arrive.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadNotifications(),
                  color: AppTheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (reveals.isNotEmpty) ...[
                        _buildSectionHeader('Connection & Reveals', Icons.handshake_outlined),
                        const SizedBox(height: 8),
                        ...reveals.map((n) => _buildNotificationCard(n)),
                        const SizedBox(height: 16),
                      ],
                      if (replies.isNotEmpty) ...[
                        _buildSectionHeader('Mentorship & Replies', Icons.chat_bubble_outline_rounded),
                        const SizedBox(height: 8),
                        ...replies.map((n) => _buildNotificationCard(n)),
                        const SizedBox(height: 16),
                      ],
                      if (system.isNotEmpty) ...[
                        _buildSectionHeader('System Announcements', Icons.info_outline_rounded),
                        const SizedBox(height: 8),
                        ...system.map((n) => _buildNotificationCard(n)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    Color iconBg;
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case 'REVEAL_REQUEST':
        iconBg = const Color(0xFFF3E8FF);
        icon = Icons.person_search_rounded;
        iconColor = Colors.purple;
        break;
      case 'REVEAL_ACCEPTED':
        iconBg = const Color(0xFFD1FAE5);
        icon = Icons.handshake_rounded;
        iconColor = AppTheme.success;
        break;
      case 'NEW_RESPONSE':
      default:
        iconBg = const Color(0xFFDFF1F5);
        icon = Icons.forum_rounded;
        iconColor = AppTheme.primary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: item.isRead ? AppTheme.surfaceContainerLow : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isRead ? AppTheme.cardBorder : AppTheme.primaryContainer.withValues(alpha: 0.4),
          width: item.isRead ? 1 : 1.5,
        ),
        boxShadow: item.isRead ? null : const [AppTheme.ambientShadow],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ),
            if (!item.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.body, style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, height: 1.3)),
            const SizedBox(height: 6),
            Text(
              _formatTimestamp(item.timestamp),
              style: TextStyle(fontSize: 11, color: AppTheme.outline),
            ),
          ],
        ),
        onTap: () {
          setState(() => item.isRead = true);
          if (item.type == 'REVEAL_REQUEST' || item.type == 'REVEAL_ACCEPTED') {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PendingRevealsScreen()));
          } else if (item.resourceId != null) {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => QueryDetailScreen(queryId: item.resourceId!)));
          }
        },
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
