import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/query_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/role_selection_screen.dart';
import '../../matching/screens/matched_queries_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/points_badges_screen.dart';
import '../../reveal/screens/pending_reveals_screen.dart';
import 'create_query_screen.dart';
import 'query_detail_screen.dart';

class QueryFeedScreen extends StatefulWidget {
  const QueryFeedScreen({super.key});

  @override
  State<QueryFeedScreen> createState() => _QueryFeedScreenState();
}

class _QueryFeedScreenState extends State<QueryFeedScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
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
      final snapshot = await FirebaseFirestore.instance
          .collection('queries')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _queries = snapshot.docs.map((doc) {
            final data = doc.data();
            return QueryModel(
              id: doc.id,
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              tags: data['category'] ?? data['tags'] ?? 'Campus',
              isAnonymousDisplay: data['isAnonymous'] ?? true,
              juniorId: data['authorUid'],
              juniorName: data['authorName'] ?? 'Anonymous Junior',
              juniorBranch: data['targetBranch'],
              juniorSemester: null,
              identityRevealedToViewer: false,
              status: 'OPEN',
              responsesCount: data['responseCount'] ?? 0,
              responses: [],
              createdAt: 'Recent',
            );
          }).toList();
        });
      } else {
        // Fallback sample data
        setState(() {
          _queries = [
            QueryModel(
              id: 'q1',
              title: 'Tips for cracking IT/Software internships in 3rd year?',
              content: 'Which DSA topics and frameworks are most asked in on-campus placements?',
              tags: 'Career,Placements,DSA',
              isAnonymousDisplay: true,
              juniorName: 'Anonymous Junior',
              juniorBranch: 'Information Technology',
              juniorSemester: 5,
              identityRevealedToViewer: false,
              status: 'OPEN',
              responsesCount: 2,
              responses: [],
              createdAt: '2h ago',
            ),
            QueryModel(
              id: 'q2',
              title: 'Best faculty and preparation strategy for OS and DBMS?',
              content: 'Looking for recommended notes, previous papers, and YouTube channels.',
              tags: 'Academics,OS,DBMS',
              isAnonymousDisplay: false,
              juniorName: 'Aman Sharma',
              juniorBranch: 'Computer Science',
              juniorSemester: 4,
              identityRevealedToViewer: false,
              status: 'OPEN',
              responsesCount: 1,
              responses: [],
              createdAt: '5h ago',
            ),
          ];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
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
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final appUser = _apiClient.currentUser;
    final isSenior = appUser?.isSenior ?? false;

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
                'Campus',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          if (isSenior)
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
              tooltip: 'Matched Queries',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MatchedQueriesScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.onSurface),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.handshake_outlined, color: AppTheme.onSurface),
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
            tooltip: 'Logout / Profile',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // User Welcome Banner
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
                    (firebaseUser?.displayName?.isNotEmpty == true)
                        ? firebaseUser!.displayName![0].toUpperCase()
                        : (firebaseUser?.email?.isNotEmpty == true ? firebaseUser!.email![0].toUpperCase() : 'U'),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firebaseUser?.displayName ?? firebaseUser?.email ?? 'Campus Student',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.onSurface),
                      ),
                      Text(
                        isSenior ? 'Senior Mentor • Verified Community' : 'Junior Student • Verified Community',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isSenior) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      backgroundColor: AppTheme.primaryContainer,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PointsBadgesScreen()),
                      );
                    },
                    icon: const Icon(Icons.emoji_events, size: 14, color: Colors.white),
                    label: const Text('Badges', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ] else ...[
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
                        Text('Verified', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
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
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
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
          if (idx == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          } else if (idx == 2) {
            if (isSenior) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PointsBadgesScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PendingRevealsScreen()),
              );
            }
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Feed'),
          const BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), label: 'Alerts'),
          BottomNavigationBarItem(
            icon: Icon(isSenior ? Icons.emoji_events_outlined : Icons.handshake_outlined),
            label: isSenior ? 'Badges' : 'Reveals',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateQueryScreen()),
          );
          if (created == true) _fetchQueries();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ask Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
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
                        borderRadius: BorderRadius.circular(9999),
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
