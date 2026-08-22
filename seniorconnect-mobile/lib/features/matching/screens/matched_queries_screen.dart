import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/query_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
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
        final List items = data['content'] ?? [];
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Matched Queries',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.onSurface),
            ),
            Text(
              'Questions matching your skills and branch',
              style: TextStyle(fontSize: 12, color: AppTheme.outline),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMatchedQueries,
        color: AppTheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
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
                                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome, size: 40, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Matched Queries Right Now',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.onSurface),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'When junior students post questions matching your tags or branch, they will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
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
                          return _buildMatchCard(query);
                        },
                      ),
      ),
    );
  }

  Widget _buildMatchCard(QueryModel query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [AppTheme.ambientShadow],
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF1F5),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          query.juniorBranch ?? 'General',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('MATCHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                query.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                query.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.4),
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
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$t', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.outline),
                  const SizedBox(width: 4),
                  Text('${query.responsesCount} responses', style: TextStyle(fontSize: 12, color: AppTheme.outline)),
                  const Spacer(),
                  const Text('Answer Query →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
