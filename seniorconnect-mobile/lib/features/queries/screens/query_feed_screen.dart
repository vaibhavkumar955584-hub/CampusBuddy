import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/query_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../reveal/screens/pending_reveals_screen.dart';
import 'create_query_screen.dart';
import 'query_detail_screen.dart';

class QueryFeedScreen extends StatefulWidget {
  const QueryFeedScreen({super.key});

  @override
  State<QueryFeedScreen> createState() => _QueryFeedScreenState();
}

class _QueryFeedScreenState extends State<QueryFeedScreen> {
  final ApiClient _apiClient = ApiClient();
  List<QueryModel> _queries = [];
  bool _isLoading = true;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchQueries();
  }

  Future<void> _fetchQueries() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiConstants.queries);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> content = data['content'] ?? [];
        setState(() {
          _queries = content.map((q) => QueryModel.fromJson(q)).toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _apiClient.post(ApiConstants.logout);
    await _apiClient.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
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
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'SC',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Home',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          if (user != null && user.isJunior)
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.onSurface),
              tooltip: 'Reveal Requests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingRevealsScreen()),
                );
              },
            ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // User Welcome Card with subtle teal tint
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
              boxShadow: const [AppTheme.ambientShadow],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFDFF1F5),
                  child: Text(
                    user != null ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? user.fullName : 'Guest Student',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.onSurface),
                    ),
                    Text(
                      user != null ? '${user.role} • ${user.branch ?? "Campus"}' : 'Campus Mentorship',
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF1F5),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_outlined, color: AppTheme.primary, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Zero-Trust',
                        style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _queries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 54, color: AppTheme.outlineVariant),
                            const SizedBox(height: 12),
                            const Text('No campus questions yet', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 15)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _fetchQueries,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _queries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final q = _queries[index];
                            return _buildQueryCard(q);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (idx) {
          setState(() => _selectedNavIndex = idx);
          if (idx == 1 && user != null && user.isJunior) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PendingRevealsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      floatingActionButton: user != null && user.isJunior
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateQueryScreen()),
                );
                if (created == true) _fetchQueries();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ask Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildQueryCard(QueryModel query) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: const [AppTheme.ambientShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QueryDetailScreen(queryId: query.id)),
            ).then((_) => _fetchQueries());
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: query.isAnonymousDisplay
                            ? const Color(0xFFF3E8FF)
                            : const Color(0xFFDFF1F5),
                        borderRadius: BorderRadius.circular(9999), // Pill
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            query.isAnonymousDisplay ? Icons.visibility_off_outlined : Icons.person_outline,
                            size: 13,
                            color: query.isAnonymousDisplay ? Colors.purple : AppTheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            query.juniorName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: query.isAnonymousDisplay ? Colors.purple : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (query.juniorBranch != null)
                      Text(
                        '• ${query.juniorBranch}',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: query.isResolved
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        query.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: query.isResolved ? AppTheme.success : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  query.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  query.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (query.tags != null && query.tags!.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: query.tags!.split(',').map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF1F5),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '#$t',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                            ),
                          );
                        }).toList(),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.mode_comment_outlined, size: 14, color: AppTheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${query.responsesCount} answers',
                          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
