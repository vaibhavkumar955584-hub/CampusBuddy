import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Map<String, dynamic>? _autoParsed;

  @override
  void initState() {
    super.initState();

    _autoParsed = widget.parsedData ?? _parseEmailMetadata(widget.email);
    final p = _autoParsed;

    String initialName = '';
    if (p != null && p['name'] != null && (p['name'] as String).isNotEmpty) {
      initialName = p['name'];
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        initialName = user.displayName!;
      } else {
        final emailPart = widget.email.split('@').first;
        initialName = _cleanName(emailPart);
      }
    }
    _nameController = TextEditingController(text: initialName);

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
      _tags = rawTags.map((t) => t.toString()).toSet().toList();
    } else {
      _tags = [defaultBranch, '2024 Batch', '3rd Year'];
    }

    _customTagController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  static String _cleanName(String raw) {
    if (raw.isEmpty) return 'Student';
    // If raw is like "vaibhav.24gcebit052", take "vaibhav"
    String first = raw.contains('.') ? raw.split('.').first : raw;
    // Strip digits
    first = first.replaceAll(RegExp(r'[0-9_]'), '');
    if (first.isEmpty) return 'Student';
    return first[0].toUpperCase() + first.substring(1).toLowerCase();
  }

  static Map<String, dynamic>? _parseEmailMetadata(String email) {
    if (!email.contains('@')) return null;
    final prefix = email.split('@').first.toLowerCase();

    // Regex to match admission year + [gce] + branch code + roll number
    // Handles: vaibhav.24gcebit052, 24gcebit052, aman.23gcebcs012, etc.
    final match = RegExp(r'(?:^|[._])(\d{2})(?:gce)?([a-z]+)(\d{2,4})', caseSensitive: false).firstMatch(prefix);
    if (match != null) {
      final yearStr = match.group(1)!;
      final rawBranch = match.group(2)!.toLowerCase();
      final roll = match.group(3)!;

      final admissionYear = 2000 + int.parse(yearStr);
      final batchLabel = '$admissionYear Batch';

      const branchMap = {
        'bit': 'Information Technology',
        'it': 'Information Technology',
        'bcs': 'Computer Science & Engineering',
        'cse': 'Computer Science & Engineering',
        'bce': 'Electronics & Communication Engineering',
        'ece': 'Electronics & Communication Engineering',
        'bee': 'Electrical & Electronics Engineering',
        'eee': 'Electrical & Electronics Engineering',
        'bme': 'Mechanical Engineering',
        'me': 'Mechanical Engineering',
        'bcv': 'Civil Engineering',
        'ce': 'Civil Engineering',
        'bai': 'Artificial Intelligence & Machine Learning',
        'aiml': 'Artificial Intelligence & Machine Learning',
        'bds': 'Data Science',
        'ds': 'Data Science',
      };

      final branchName = branchMap[rawBranch] ?? 'Information Technology';

      final now = DateTime.now();
      int academicYear = now.year - admissionYear + (now.month >= 8 ? 1 : 0);
      String yearLabel;
      if (academicYear <= 1) {
        yearLabel = '1st Year';
      } else if (academicYear == 2) {
        yearLabel = '2nd Year';
      } else if (academicYear == 3) {
        yearLabel = '3rd Year';
      } else if (academicYear == 4) {
        yearLabel = '4th Year';
      } else {
        yearLabel = 'Alumni';
      }

      String name = _cleanName(prefix);

      return {
        'isMatched': true,
        'name': name,
        'branchName': branchName,
        'branchCode': rawBranch,
        'batchLabel': batchLabel,
        'yearLabel': yearLabel,
        'rollNumber': roll,
        'autoTags': [branchName, batchLabel, yearLabel],
      };
    }
    return null;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final finalName = _nameController.text.trim();
        if (finalName.isNotEmpty) {
          await user.updateDisplayName(finalName);
        }
        await _apiClient.markProfileCompleted(user.uid);
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QueryFeedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _autoParsed;
    final isAutoMatched = p != null && p['isMatched'] == true;

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
          'Complete Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review the auto-detected information below and personalize your academic tags.',
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 20),
              if (isAutoMatched)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF1F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBCE3EC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Smart Email Parsing Active',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pre-filled from roll format (${p['batchLabel'] ?? ""}, ${p['branchCode']?.toString().toUpperCase() ?? ""}). Editable anytime.',
                              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
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
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select your branch and academic year below to finalize your campus profile.',
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.outline),
                ),
              ),

              const SizedBox(height: 20),
              const Text('Branch / Department', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _standardBranches.contains(_branchController.text)
                    ? _branchController.text
                    : 'Other / Dual Degree',
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined, size: 20, color: AppTheme.outline),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                dropdownColor: AppTheme.surfaceContainerLowest,
                items: _standardBranches.map((b) {
                  return DropdownMenuItem(
                    value: b,
                    child: Text(
                      b,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
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
                  const Text('Year of Study', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Editable', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedYearOfStudy,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.outline),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                dropdownColor: AppTheme.surfaceContainerLowest,
                items: _yearOptions.map((y) {
                  return DropdownMenuItem(
                    value: y,
                    child: Text(
                      y,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYearOfStudy = val);
                  }
                },
              ),

              const SizedBox(height: 24),
              const Text('Auto-Generated Profile Tags (Pills)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.onSurface)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    backgroundColor: const Color(0xFFDFF1F5),
                    side: const BorderSide(color: Color(0xFFC8E4EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                    label: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.primary),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagController,
                      decoration: const InputDecoration(
                        hintText: 'Add custom tag (e.g. Flutter, Placements)...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 28),
                  ),
                ],
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Confirm & Enter Campus Feed',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
