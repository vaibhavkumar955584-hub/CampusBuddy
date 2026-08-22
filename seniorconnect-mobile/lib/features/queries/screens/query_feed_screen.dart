import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/query_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/otp_login_screen.dart';
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
        MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiClient.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 22),
            const SizedBox(width: 8),
            const Text(
              'SeniorConnect',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (user != null && user.isJunior)
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              tooltip: 'Reveal Requests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingRevealsScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.darkSurface.withOpacity(0.5),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    user != null ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user != null ? user.fullName : 'Guest',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      user != null ? '${user.role} • ${user.branch ?? "Campus"}' : '',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, color: AppTheme.accentColor, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Zero-Trust',
                        style: TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
                : _queries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 54, color: AppTheme.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text('No campus queries yet', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
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
      floatingActionButton: user != null && user.isJunior
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateQueryScreen()),
                );
                if (created == true) _fetchQueries();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ask Anonymously', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildQueryCard(QueryModel query) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: query.isAnonymousDisplay
                          ? Colors.purple.withOpacity(0.15)
                          : AppTheme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          query.isAnonymousDisplay ? Icons.visibility_off_outlined : Icons.person_outline,
                          size: 13,
                          color: query.isAnonymousDisplay ? Colors.purpleAccent : AppTheme.primaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          query.juniorName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: query.isAnonymousDisplay ? Colors.purpleAccent : AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (query.juniorBranch != null)
                    Text(
                      '• ${query.juniorBranch}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: query.isResolved ? AppTheme.accentColor.withOpacity(0.15) : AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      query.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: query.isResolved ? AppTheme.accentColor : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                query.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                query.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (query.tags != null && query.tags!.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: query.tags!.split(',').map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('#$t', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        );
                      }).toList(),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${query.responsesCount} answers',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
