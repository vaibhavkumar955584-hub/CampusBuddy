import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../queries/screens/query_feed_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? parsedData;

  const ProfileSetupScreen({
    super.key,
    required this.email,
    this.parsedData,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ApiClient _apiClient = ApiClient();

  late TextEditingController _nameController;
  late TextEditingController _branchController;
  late TextEditingController _customTagController;

  String _selectedYearOfStudy = '3rd Year';
  final List<String> _yearOptions = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Alumni',
  ];

  final List<String> _standardBranches = [
    'Information Technology',
    'Computer Science & Engineering',
    'Electronics & Communication Engineering',
    'Electrical & Electronics Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Artificial Intelligence & Machine Learning',
    'Data Science',
    'Other / Dual Degree',
  ];

  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.parsedData;

    _nameController = TextEditingController(
      text: _apiClient.currentUser?.fullName ?? widget.email.split('@')[0],
    );

    String defaultBranch = p != null && p['branchName'] != null
        ? p['branchName']
        : 'Information Technology';
    _branchController = TextEditingController(text: defaultBranch);

    if (p != null && p['yearLabel'] != null) {
      String yLabel = p['yearLabel'];
      if (_yearOptions.contains(yLabel)) {
        _selectedYearOfStudy = yLabel;
      }
    }

    if (p != null && p['autoTags'] != null) {
      final rawTags = p['autoTags'] as List<dynamic>;
      _tags = rawTags.map((t) => t.toString()).toList();
    } else {
      _tags = [defaultBranch, '2024 Batch', '3rd Year'];
    }

    _customTagController = TextEditingController();
  }

  void _addTag() {
    final text = _customTagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _customTagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    try {
      // Profile data confirmed by user
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QueryFeedScreen()),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parsedData;
    final isAutoMatched = p != null && p['isMatched'] == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Review & Customize Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAutoMatched)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.accentColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Smart Email Parsing Active',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pre-filled from roll format (${p['batchLabel'] ?? ""}, ${p['branchCode']?.toString().toUpperCase() ?? ""}). Review and edit below:',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Non-standard roll format detected. Please select your branch and academic year manually.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Branch / Department', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _standardBranches.contains(_branchController.text)
                    ? _branchController.text
                    : 'Other / Dual Degree',
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                ),
                dropdownColor: AppTheme.darkSurface,
                items: _standardBranches.map((b) {
                  return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _branchController.text = val;
                      if (!_tags.contains(val)) _tags.add(val);
                    });
                  }
                },
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Year of Study', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Editable for lateral/repeaters', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedYearOfStudy,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                dropdownColor: AppTheme.darkSurface,
                items: _yearOptions.map((y) {
                  return DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 14)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYearOfStudy = val);
                  }
                },
              ),

              const SizedBox(height: 24),
              const Text('Auto-Generated Profile Tags (Editable)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.18),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                    label: Text(tag, style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight)),
                    deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.primaryLight),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom tag (e.g. Flutter, Placements)...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryLight, size: 28),
                  ),
                ],
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      : const Text('Confirm & Enter Campus Feed'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
