import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/query_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/anonymity_badge.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../queries/screens/query_detail_screen.dart';

class MatchedQueriesScreen extends StatefulWidget {
  const MatchedQueriesScreen({super.key});

  @override
  State<MatchedQueriesScreen> createState() => _MatchedQueriesScreenState();
}

class _MatchedQueriesScreenState extends State<MatchedQueriesScreen> {
  final ApiClient _apiClient = ApiClient();
  List<QueryModel> _matchedQueries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMatchedQueries();
  }

  Future<void> _fetchMatchedQueries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(ApiConstants.matchedQueries);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List items = data['content'] ?? (data is List ? data : []);
        setState(() {
          _matchedQueries = items.map((q) => QueryModel.fromJson(q)).toList();
        });
      } else {
        setState(() => _errorMessage = 'Failed to load matched queries (HTTP ${res.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error loading matched queries');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matched Queries',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? AppTheme.darkOnSurface : AppTheme.onSurface,
              ),
            ),
            Text(
              'Questions matching your skills and branch',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkOutline : AppTheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMatchedQueries,
        color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
        child: _isLoading
            ? const SkeletonFeedList(count: 4)
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchMatchedQueries,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _matchedQueries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppTheme.darkPrimary : AppTheme.primary).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 40,
                                  color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Matched Queries Right Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? AppTheme.darkOnSurface : AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When junior students post questions matching your tags or branch, they will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _matchedQueries.length,
                        itemBuilder: (context, index) {
                          final query = _matchedQueries[index];
                          return _buildMatchCard(query, isDark);
                        },
                      ),
      ),
    );
  }

  Widget _buildMatchCard(QueryModel query, bool isDark) {
    final cardBg = isDark ? AppTheme.darkSurfaceContainer : AppTheme.surfaceContainerLowest;
    final cardBorder = isDark ? AppTheme.darkCardBorder : AppTheme.cardBorder;
    final primaryCol = isDark ? AppTheme.darkPrimary : AppTheme.primary;
    final onSurfaceCol = isDark ? AppTheme.darkOnSurface : AppTheme.onSurface;
    final onSurfaceVar = isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.onSurfaceVariant;
    final outlineCol = isDark ? AppTheme.darkOutline : AppTheme.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [isDark ? AppTheme.darkAmbientShadow : AppTheme.ambientShadow],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => QueryDetailScreen(queryId: query.id)),
          ).then((_) => _fetchMatchedQueries());
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Anonymity Badge + Branch Pill + Match Badge
              Row(
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: AnonymityBadge(
                            isAnonymous: query.isAnonymousDisplay,
                            studentName: query.juniorName,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDFF1F5),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_rounded, size: 11, color: primaryCol),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    query.juniorBranch ?? 'General',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: primaryCol),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('MATCHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                query.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurfaceCol),
              ),
              const SizedBox(height: 6),
              Text(
                query.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: onSurfaceVar, fontSize: 13, height: 1.4),
              ),
              if (query.tags != null && query.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: query.tags!.split(',').map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF21262D) : AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$t', style: TextStyle(fontSize: 11, color: primaryCol, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: outlineCol),
                  const SizedBox(width: 4),
                  Text('${query.responsesCount} responses', style: TextStyle(fontSize: 12, color: outlineCol)),
                  const Spacer(),
                  Text('Answer Query →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryCol)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
