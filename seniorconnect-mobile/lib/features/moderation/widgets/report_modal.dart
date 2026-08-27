import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ReportModal extends StatefulWidget {
  final String targetType; // 'QUERY' or 'RESPONSE'
  final String targetId;
  final String? reportedUserId;
  final String? targetTitle;

  const ReportModal({
    super.key,
    required this.targetType,
    required this.targetId,
    this.reportedUserId,
    this.targetTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    String? reportedUserId,
    String? targetTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportModal(
        targetType: targetType,
        targetId: targetId,
        reportedUserId: reportedUserId,
        targetTitle: targetTitle,
      ),
    );
  }

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reasons = [
    'Harassment / Bullying / Hate Speech',
    'Inappropriate or Offensive Content',
    'Spam, Advertisement, or Irrelevant',
    'Violates Identity Privacy or Anonymity',
    'Misinformation or Malicious Advice',
    'Other Policy Violation',
  ];

  String? _selectedReason;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      setState(() => _errorMessage = 'Please select a reason for reporting');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final reasonText = _detailsController.text.trim().isNotEmpty
        ? '$_selectedReason: ${_detailsController.text.trim()}'
        : _selectedReason!;

    try {
      final Map<String, dynamic> body = {
        'targetType': widget.targetType,
        'targetId': widget.targetId,
        'reason': reasonText,
      };
      if (widget.reportedUserId != null) {
        body['reportedUserId'] = widget.reportedUserId;
      }

      final res = await _apiClient.post(
        ApiConstants.reports,
        body: body,
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted to moderators for review. Thank you.'),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      } else {
        final err = jsonDecode(res.body);
        setState(() => _errorMessage = err['message'] ?? 'Failed to submit report');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error submitting report. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppTheme.secondary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Report ${widget.targetType == "QUERY" ? "Question" : "Response"}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            if (widget.targetTitle != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.targetTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
              ),
            ],
            const Text(
              'Select Reason',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
            ..._reasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryContainer.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppTheme.primary : AppTheme.outline,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppTheme.primary : AppTheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              'Additional Details (Optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Provide any context to help moderators investigate...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
