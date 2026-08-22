import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class CreateQueryScreen extends StatefulWidget {
  const CreateQueryScreen({super.key});

  @override
  State<CreateQueryScreen> createState() => _CreateQueryScreenState();
}

class _CreateQueryScreenState extends State<CreateQueryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isAnonymous = true;
  bool _isLoading = false;
  String? _errorMessage;

  final ApiClient _apiClient = ApiClient();

  Future<void> _submitQuery() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide both title and question details.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.post(
        ApiConstants.queries,
        body: {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'tags': _tagsController.text.trim(),
          'isAnonymousDisplay': _isAnonymous,
        },
      );

      if (res.statusCode == 201) {
        if (mounted) Navigator.pop(context, true);
      } else {
        final err = jsonDecode(res.body);
        setState(() => _errorMessage = err['message'] ?? 'Failed to submit query');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Network error while posting query.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Ask Seniors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.dangerColor, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isAnonymous ? Colors.purple.withOpacity(0.1) : AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isAnonymous ? Colors.purple.withOpacity(0.3) : const Color(0xFF334155),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAnonymous ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: _isAnonymous ? Colors.purpleAccent : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAnonymous ? 'Anonymous Mode Active' : 'Public Mode',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isAnonymous
                              ? 'Your name and exact batch are masked to all seniors by default.'
                              : 'Your name will be visible to mentors.',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Question Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Which electives are best for backend systems?',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Details & Context', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe your background, what you have tried, and where you need guidance...',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Tags (comma separated)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                hintText: 'e.g. electives, placements, spring-boot',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitQuery,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                    : const Text('Post Query to Campus'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
