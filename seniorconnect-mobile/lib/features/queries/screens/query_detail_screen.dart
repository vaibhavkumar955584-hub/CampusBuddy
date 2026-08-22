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
  bool _isSubmitting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _fetchQueryDetails();
  }

  Future<void> _fetchQueryDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('${ApiConstants.queries}/${widget.queryId}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _query = QueryModel.fromJson(data);
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestReveal() async {
    try {
      final res = await _apiClient.post(
        ApiConstants.reveals,
        body: {'queryId': widget.queryId},
      );
      if (res.statusCode == 201) {
        setState(() => _statusMessage = 'Reveal request submitted! Awaiting junior consent.');
      } else {
        final err = jsonDecode(res.body);
        setState(() => _statusMessage = err['message'] ?? 'Failed to request reveal');
      }
    } catch (_) {
      setState(() => _statusMessage = 'Error sending reveal request');
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await _apiClient.post(
        ApiConstants.responses(widget.queryId),
        body: {'content': _answerController.text.trim()},
      );

      if (res.statusCode == 201) {
        _answerController.clear();
        await _fetchQueryDetails();
      }
    } catch (_) {
    } finally {
      setState(() => _isSubmitting = false);
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
        title: const Text('Question Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.onSurface)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _query == null
              ? const Center(child: Text('Failed to load question details'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_statusMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primaryContainer.withValues(alpha: 0.3)),
                                ),
                                child: Text(_statusMessage!, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ],
                            // Main Query Card
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.cardBorder),
                                boxShadow: const [AppTheme.ambientShadow],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _query!.isAnonymousDisplay ? const Color(0xFFF3E8FF) : const Color(0xFFDFF1F5),
                                          borderRadius: BorderRadius.circular(9999),
                                        ),
                                        child: Text(
                                          _query!.juniorName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _query!.isAnonymousDisplay ? Colors.purple : AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (user != null && user.isSenior && _query!.isAnonymousDisplay && !_query!.identityRevealedToViewer)
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: const Size(0, 36),
                                          ),
                                          onPressed: _requestReveal,
                                          icon: const Icon(Icons.handshake_outlined, size: 16),
                                          label: const Text('Request Reveal', style: TextStyle(fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _query!.title,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _query!.content,
                                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 15, height: 1.5),
                                  ),
                                  if (_query!.tags != null && _query!.tags!.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      children: _query!.tags!.split(',').map((t) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDFF1F5),
                                            borderRadius: BorderRadius.circular(9999),
                                          ),
                                          child: Text('#$t', style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Mentor Responses (${_query!.responses.length})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                            ),
                            const SizedBox(height: 12),
                            if (_query!.responses.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text('No mentor responses yet. Seniors have been notified.', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                                ),
                              )
                            else
                              ..._query!.responses.map((resp) => _buildResponseCard(resp)),
                          ],
                        ),
                      ),
                    ),
                    if (user != null && user.isSenior) _buildAnswerInput(),
                  ],
                ),
    );
  }

  Widget _buildResponseCard(AnswerModel resp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: resp.isAcceptedAnswer ? AppTheme.success : AppTheme.cardBorder,
          width: resp.isAcceptedAnswer ? 1.5 : 1,
        ),
        boxShadow: const [AppTheme.ambientShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryContainer,
                child: Text(resp.seniorName[0], style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(resp.seniorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.onSurface)),
              const SizedBox(width: 6),
              if (resp.placementTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF1F5),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(resp.placementTag!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    ],
                  ),
                ),
              const Spacer(),
              if (resp.isAcceptedAnswer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ACCEPTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(resp.content, style: const TextStyle(color: AppTheme.onSurface, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: 'Provide guidance or advice...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _isSubmitting ? null : _submitAnswer,
            icon: const Icon(Icons.send_rounded, color: AppTheme.primary, size: 24),
          ),
        ],
      ),
    );
  }
}
