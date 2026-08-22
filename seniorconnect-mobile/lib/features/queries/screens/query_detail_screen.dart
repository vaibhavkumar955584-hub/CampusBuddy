import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/query_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class QueryDetailScreen extends StatefulWidget {
  final String queryId;

  const QueryDetailScreen({super.key, required this.queryId});

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _answerController = TextEditingController();

  QueryModel? _query;
  bool _isLoading = true;
  bool _isPostingAnswer = false;
  bool _isRequestingReveal = false;

  @override
  void initState() {
    super.initState();
    _fetchQueryDetail();
  }

  Future<void> _fetchQueryDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('${ApiConstants.queries}/${widget.queryId}');
      if (res.statusCode == 200) {
        setState(() {
          _query = QueryModel.fromJson(jsonDecode(res.body));
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    setState(() => _isPostingAnswer = true);
    try {
      final res = await _apiClient.post(
        '${ApiConstants.queries}/${widget.queryId}/responses',
        body: {'content': _answerController.text.trim()},
      );

      if (res.statusCode == 201) {
        _answerController.clear();
        await _fetchQueryDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mentorship response posted! +10 Points awarded.')),
          );
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['message'] ?? 'Failed to post response')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error posting answer')),
        );
      }
    } finally {
      setState(() => _isPostingAnswer = false);
    }
  }

  Future<void> _requestReveal() async {
    setState(() => _isRequestingReveal = true);
    try {
      final res = await _apiClient.post('${ApiConstants.reveals}/query/${widget.queryId}/request');
      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identity reveal request sent to junior.')),
          );
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['message'] ?? 'Unable to request reveal')),
          );
        }
      }
    } catch (_) {
    } finally {
      setState(() => _isRequestingReveal = false);
    }
  }

  Future<void> _acceptAnswer(String responseId) async {
    try {
      final res = await _apiClient.post('${ApiConstants.queries}/${widget.queryId}/responses/$responseId/accept');
      if (res.statusCode == 200) {
        await _fetchQueryDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer accepted and marked as resolved!')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiClient.currentUser;
    final isAuthor = user != null && _query != null && _query!.juniorId == user.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Discussion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
          : _query == null
              ? const Center(child: Text('Query not found'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Query Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _query!.isAnonymousDisplay
                                      ? Colors.purple.withOpacity(0.2)
                                      : AppTheme.primaryColor.withOpacity(0.2),
                                  child: Icon(
                                    _query!.isAnonymousDisplay ? Icons.visibility_off : Icons.person,
                                    size: 18,
                                    color: _query!.isAnonymousDisplay ? Colors.purpleAccent : AppTheme.primaryLight,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _query!.juniorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: _query!.isAnonymousDisplay
                                                ? Colors.purpleAccent
                                                : Colors.white,
                                          ),
                                        ),
                                        if (_query!.identityRevealedToViewer) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('Revealed to You',
                                                style: TextStyle(fontSize: 10, color: AppTheme.accentColor)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      _query!.juniorBranch ?? 'Campus Student',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (user != null && user.isSenior && _query!.isAnonymousDisplay && !_query!.identityRevealedToViewer)
                                  OutlinedButton.icon(
                                    onPressed: _isRequestingReveal ? null : _requestReveal,
                                    icon: const Icon(Icons.key_outlined, size: 14),
                                    label: const Text('Request Reveal', style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryLight,
                                      side: const BorderSide(color: AppTheme.primaryLight),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _query!.title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _query!.content,
                              style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFFCBD5E1)),
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFF334155)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  'Answers (${_query!.responses.length})',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                if (_query!.isResolved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Resolved',
                                      style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_query!.responses.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    user != null && user.isSenior
                                        ? 'Be the first senior to share advice!'
                                        : 'Waiting for senior responses...',
                                    style: const TextStyle(color: AppTheme.textSecondary),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _query!.responses.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final answer = _query!.responses[idx];
                                  return _buildAnswerCard(answer, isAuthor);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (user != null && (user.isSenior || user.isAdmin))
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _answerController,
                                decoration: const InputDecoration(
                                  hintText: 'Provide structured mentorship answer...',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _isPostingAnswer ? null : _postAnswer,
                              icon: _isPostingAnswer
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, color: AppTheme.primaryLight),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildAnswerCard(AnswerModel answer, bool isAuthor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isAcceptedAnswer ? AppTheme.accentColor.withOpacity(0.08) : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answer.isAcceptedAnswer ? AppTheme.accentColor.withOpacity(0.4) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                answer.seniorName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: 8),
              if (answer.placementTag != null && answer.placementTag!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: answer.isTagVerified ? Colors.blue.withOpacity(0.2) : AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: answer.isTagVerified ? Colors.blue.withOpacity(0.4) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (answer.isTagVerified) ...[
                        const Icon(Icons.verified, size: 12, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        answer.placementTag!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: answer.isTagVerified ? Colors.blueAccent : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (answer.isAcceptedAnswer)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.accentColor, size: 16),
                    SizedBox(width: 4),
                    Text('Accepted Answer',
                        style: TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              else if (isAuthor && !_query!.isResolved)
                TextButton.icon(
                  onPressed: () => _acceptAnswer(answer.id),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Accept', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(answer.content, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
