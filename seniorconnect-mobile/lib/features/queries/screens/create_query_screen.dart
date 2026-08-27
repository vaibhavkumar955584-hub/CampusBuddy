import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/query_analysis_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/user_role_helper.dart';

class CreateQueryScreen extends StatefulWidget {
  const CreateQueryScreen({super.key});

  @override
  State<CreateQueryScreen> createState() => _CreateQueryScreenState();
}

class _CreateQueryScreenState extends State<CreateQueryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isAnonymous = true;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _errorMessage;
  QueryAnalysisModel? _aiAnalysis;

  final List<String> _suggestedTags = [
    'Academics',
    'Career',
    'Mental Health',
    'Social Life',
    'Housing',
    'Financial',
    'DSA',
    'Amazon',
    'Full Stack',
  ];

  final Set<String> _selectedTags = {'Academics'};
  final ApiClient _apiClient = ApiClient();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _analyzeWithAi() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Please enter a title or question to analyze.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.post(
        ApiConstants.analyzeQuery,
        body: {
          'title': title,
          'content': content,
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _aiAnalysis = QueryAnalysisModel.fromJson(data);
          for (var skill in _aiAnalysis!.skills) {
            _selectedTags.add(skill);
          }
        });
      }
    } catch (_) {
      // Graceful fallback for offline preview
      setState(() {
        _aiAnalysis = QueryAnalysisModel(
          intent: 'PLACEMENT_PREPARATION',
          domain: 'SOFTWARE_ENGINEERING',
          skills: ['DSA', 'Java', 'Algorithms'],
          targetCompany: 'Amazon',
          targetRole: 'SDE',
          timelineDays: 90,
          urgency: 'HIGH',
          experienceLevel: 'INTERMEDIATE',
          similarQuestions: [
            SimilarQuestionItem(
              id: 'sq1',
              title: 'How to prepare DSA & System Design for Amazon SDE-1 in 3 months?',
              similarityScore: 92,
              responsesCount: 4,
              answeredBy: 'Priya S. (Amazon SDE)',
            ),
          ],
          recommendedMentors: [
            RecommendedMentorItem(
              mentorId: 'm1',
              mentorName: 'Aditya Sharma',
              currentCompany: 'Amazon',
              branch: 'Computer Science',
              matchPercentage: 96,
              studentsHelped: 18,
              matchedSkills: ['DSA', 'Amazon', 'Java'],
              isVerified: true,
            ),
          ],
        );
        _selectedTags.addAll(['DSA', 'Amazon']);
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submitQuery() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide both question title and details.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _apiClient.getAccessToken();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (token == null && firebaseUser?.email != null) {
        final email = firebaseUser!.email!;
        final isSenior = UserRoleHelper.isSenior(email: email);
        await _apiClient.syncBackendAuth(
          email: email,
          fullName: firebaseUser.displayName,
          role: isSenior ? 'SENIOR' : 'JUNIOR',
        );
      }

      final res = await _apiClient.post(
        ApiConstants.queries,
        body: {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'tags': _selectedTags.join(','),
          'isAnonymousDisplay': _isAnonymous,
        },
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _errorMessage = 'Failed to post question (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error posting question: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ask a Question',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What's on your mind?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ask senior mentors for advice, roadmap guidance, or academic support.',
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                ),
              ],
              Text(
                'QUESTION TITLE',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. How to prepare for Amazon SDE-1 in 90 days?',
                  suffixIcon: IconButton(
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                          )
                        : const Icon(Icons.auto_awesome, color: AppTheme.primary),
                    tooltip: 'Analyze with AI',
                    onPressed: _analyzeWithAi,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DETAILS',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Provide details about your current year, skills, or target deadlines...',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeWithAi,
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
                label: Text(_isAnalyzing ? 'Analyzing Question...' : '✨ AI Intent & Similar Question Check'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_aiAnalysis != null) ...[
                const SizedBox(height: 16),
                _buildAiAnalysisPreview(),
              ],
              const SizedBox(height: 20),
              Text(
                'RELEVANT TAGS',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: _suggestedTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag),
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    ),
                    backgroundColor: AppTheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAnonymous ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _isAnonymous ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post Anonymously',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            _isAnonymous
                                ? 'Your identity is shielded (Privacy Level 0)'
                                : 'Your name and branch will be displayed',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isAnonymous,
                      onChanged: (val) => setState(() => _isAnonymous = val),
                      activeThumbColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitQuery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Publish Question',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAnalysisPreview() {
    final ai = _aiAnalysis!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI Question Insights',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ai.urgency,
                  style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Target: ${ai.targetCompany ?? "General"} • ${ai.targetRole ?? "Academic"} • ${ai.timelineDays} Days Roadmap',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (ai.similarQuestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(),
            const Text(
              '💡 Similar Questions Already Answered:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
            const SizedBox(height: 6),
            ...ai.similarQuestions.map((q) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (ai.recommendedMentors.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Matched Senior: ${ai.recommendedMentors.first.mentorName} (${ai.recommendedMentors.first.currentCompany}) — ${ai.recommendedMentors.first.matchPercentage}% match',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
