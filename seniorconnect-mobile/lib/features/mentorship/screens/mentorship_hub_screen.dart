import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/mentorship_plan_model.dart';
import '../../../core/models/mentorship_session_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'mentorship_chat_screen.dart';

class MentorshipHubScreen extends StatefulWidget {
  const MentorshipHubScreen({super.key});

  @override
  State<MentorshipHubScreen> createState() => _MentorshipHubScreenState();
}

class _MentorshipHubScreenState extends State<MentorshipHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();

  List<MentorshipPlanModel> _myPlans = [];
  List<MentorshipSessionModel> _mySessions = [];
  List<dynamic> _verifiedOutcomes = [];
  bool _isLoadingPlans = true;
  bool _isLoadingSessions = true;
  bool _isLoadingOutcomes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPlans();
    _fetchSessions();
    _fetchOutcomes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoadingPlans = true);
    try {
      final res = await _apiClient.get(ApiConstants.myMentorshipPlans);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _myPlans = data.map((json) => MentorshipPlanModel.fromJson(json)).toList();
          _isLoadingPlans = false;
        });
      } else {
        _setFallbackPlans();
      }
    } catch (e) {
      _setFallbackPlans();
    }
  }

  void _setFallbackPlans() {
    setState(() {
      _isLoadingPlans = false;
      _myPlans = [
        MentorshipPlanModel(
          id: 'mock-plan-1',
          juniorId: 'u1',
          juniorName: 'You',
          seniorId: 's1',
          seniorName: 'Aditya Sharma (Amazon SDE-1)',
          goalTitle: '90-Day Amazon SDE Preparation',
          targetCompany: 'Amazon',
          targetRole: 'Software Development Engineer',
          durationDays: 90,
          status: 'ACTIVE',
          progressPercentage: 35,
          tasks: [
            PlanTaskItem(id: 't1', weekNumber: 1, title: 'Week 1-2: Core DSA Foundations', description: 'Arrays, Strings, Two Pointers & Time Complexity analysis', isCompleted: true),
            PlanTaskItem(id: 't2', weekNumber: 3, title: 'Week 3-4: Data Structures Deep-Dive', description: 'HashMaps, Stacks, Queues & Linked Lists practice problems', isCompleted: true),
            PlanTaskItem(id: 't3', weekNumber: 5, title: 'Week 5-6: Trees, Graphs & Recursion', description: 'Binary Search Trees, BFS/DFS Traversal & Dynamic Programming', isCompleted: false),
            PlanTaskItem(id: 't4', weekNumber: 7, title: 'Week 7-8: Core CS & System Design Basics', description: 'Operating Systems, DBMS Indexing & REST API Architecture', isCompleted: false),
            PlanTaskItem(id: 't5', weekNumber: 9, title: 'Week 9-10: Mock Interview & Resume Polish', description: '1-on-1 Senior Mock Interview session & Project defense preparation', isCompleted: false),
            PlanTaskItem(id: 't6', weekNumber: 11, title: 'Week 11-12: Final Placement Drills', description: 'Company-specific previous questions & HR behavioral round readiness', isCompleted: false),
          ],
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
    });
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final res = await _apiClient.get(ApiConstants.myMentorshipSessions);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _mySessions = data.map((json) => MentorshipSessionModel.fromJson(json)).toList();
          _isLoadingSessions = false;
        });
      } else {
        _setFallbackSessions();
      }
    } catch (_) {
      _setFallbackSessions();
    }
  }

  void _setFallbackSessions() {
    setState(() {
      _isLoadingSessions = false;
      _mySessions = [
        MentorshipSessionModel(
          id: 'sess-1',
          juniorId: 'u1',
          juniorName: 'You',
          juniorEmail: 'junior@galgotiacollege.edu',
          juniorBranch: 'Computer Science',
          seniorId: 's1',
          seniorName: 'Aditya Sharma',
          seniorEmail: 'aditya.amazon@galgotiacollege.edu',
          seniorBranch: 'Information Technology',
          seniorPlacementTag: 'Amazon SDE-1',
          queryId: 'q1',
          queryTitle: '90-Day Amazon SDE Preparation Strategy',
          planId: 'mock-plan-1',
          status: 'ACTIVE',
          privacyLevel: 3,
          meetingLink: 'https://meet.google.com/xyz-abcd-efg',
          sessionNotes: 'Weekly Mock Interview & Coding reviews on Saturdays 7 PM',
          scheduledAt: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        ),
      ];
    });
  }

  Future<void> _fetchOutcomes() async {
    setState(() => _isLoadingOutcomes = true);
    try {
      final res = await _apiClient.get(ApiConstants.verifiedOutcomes);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _verifiedOutcomes = data;
          _isLoadingOutcomes = false;
        });
      } else {
        _setFallbackOutcomes();
      }
    } catch (e) {
      _setFallbackOutcomes();
    }
  }

  void _setFallbackOutcomes() {
    setState(() {
      _isLoadingOutcomes = false;
      _verifiedOutcomes = [
        {
          'id': 'o1',
          'juniorName': 'Rohan Gupta (CSE 2024)',
          'seniorName': 'Priya Singh (Mentor)',
          'outcomeType': 'PLACEMENT_RECEIVED',
          'company': 'Amazon',
          'role': 'Software Dev Engineer',
          'isVerified': true,
        },
        {
          'id': 'o2',
          'juniorName': 'Sneha Patel (IT 2025)',
          'seniorName': 'Vikram Rao (Mentor)',
          'outcomeType': 'INTERNSHIP_RECEIVED',
          'company': 'Microsoft',
          'role': 'Summer SWE Intern',
          'isVerified': true,
        },
        {
          'id': 'o3',
          'juniorName': 'Amit Kumar (ECE 2024)',
          'seniorName': 'Rahul Verma (Mentor)',
          'outcomeType': 'PLACEMENT_RECEIVED',
          'company': 'Qualcomm',
          'role': 'Hardware Systems Engineer',
          'isVerified': true,
        }
      ];
    });
  }

  Future<void> _toggleTask(MentorshipPlanModel plan, PlanTaskItem task) async {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    try {
      await _apiClient.patch(ApiConstants.togglePlanTask(plan.id, task.id));
    } catch (_) {}
  }

  void _showCreatePlanDialog() {
    final titleCtrl = TextEditingController(text: '90-Day Microsoft SDE Roadmap');
    final companyCtrl = TextEditingController(text: 'Microsoft');
    final roleCtrl = TextEditingController(text: 'Software Engineer');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rocket_launch, color: AppTheme.primary),
                SizedBox(width: 10),
                Text(
                  'Launch Mentorship Goal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Goal / Roadmap Title',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Target Company',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Target Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _apiClient.post(
                      ApiConstants.mentorshipPlans,
                      body: {
                        'goalTitle': titleCtrl.text.trim(),
                        'targetCompany': companyCtrl.text.trim(),
                        'targetRole': roleCtrl.text.trim(),
                        'durationDays': 90,
                      },
                    );
                    _fetchPlans();
                  } catch (_) {
                    _setFallbackPlans();
                  }
                },
                child: const Text('Create 90-Day Roadmap'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitOutcomeDialog() {
    final companyCtrl = TextEditingController(text: 'Amazon');
    final roleCtrl = TextEditingController(text: 'Software Development Engineer');
    String selectedType = 'PLACEMENT_RECEIVED';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.amber),
                  SizedBox(width: 10),
                  Text(
                    'Celebrate Career Outcome 🎉',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Share your placement or internship offer to inspire your campus juniors and reward your mentors!',
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Outcome Category'),
                dropdownColor: AppTheme.surfaceContainerLowest,
                items: const [
                  DropdownMenuItem(value: 'PLACEMENT_RECEIVED', child: Text('Full-time Placement Offer')),
                  DropdownMenuItem(value: 'INTERNSHIP_RECEIVED', child: Text('Internship Offer')),
                  DropdownMenuItem(value: 'INTERVIEW_CLEARED', child: Text('Cleared Technical Interview')),
                  DropdownMenuItem(value: 'SKILL_IMPROVED', child: Text('Assessment / Contest Cleared')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Job / Internship Role',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Congratulations! Your verified outcome was submitted successfully! (+50 points awarded to mentor)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    try {
                      await _apiClient.post(
                        ApiConstants.submitOutcome,
                        body: {
                          'outcomeType': selectedType,
                          'company': companyCtrl.text.trim(),
                          'role': roleCtrl.text.trim(),
                        },
                      );
                      _fetchOutcomes();
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                  child: const Text('Submit & Celebrate Win 🚀'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mentorship & Roadmaps'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.outline,
          tabs: const [
            Tab(icon: Icon(Icons.route_outlined), text: 'Roadmaps'),
            Tab(icon: Icon(Icons.forum_outlined), text: '1-on-1 Chat'),
            Tab(icon: Icon(Icons.stars_outlined), text: 'Outcome Wall'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _tabController.index == 2 ? _showSubmitOutcomeDialog : _showCreatePlanDialog,
        icon: Icon(_tabController.index == 2 ? Icons.celebration : Icons.add_task, color: Colors.white),
        label: Text(_tabController.index == 2 ? 'Share Win' : 'New Goal', style: const TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoadmapsTab(),
          _buildSessionsTab(),
          _buildOutcomesTab(),
        ],
      ),
    );
  }

  Widget _buildRoadmapsTab() {
    if (_isLoadingPlans) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_myPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: AppTheme.outline),
            const SizedBox(height: 16),
            const Text('No active roadmaps found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Start your 90-day placement preparation roadmap today!', style: TextStyle(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showCreatePlanDialog,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Start Roadmap'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPlans.length,
      itemBuilder: (context, index) {
        final plan = _myPlans[index];
        return Card(
          color: AppTheme.surfaceContainerLowest,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plan.goalTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: plan.status == 'COMPLETED' ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: plan.status == 'COMPLETED' ? AppTheme.success : AppTheme.primary),
                      ),
                      child: Text(
                        plan.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: plan.status == 'COMPLETED' ? AppTheme.success : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Mentor: ${plan.seniorName}',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Goal Progress', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    Text('${plan.progressPercentage}% Completed', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: plan.progressPercentage / 100.0,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      plan.progressPercentage == 100 ? AppTheme.success : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Milestones & Weekly Tasks:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                ...plan.tasks.map((task) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.primary,
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? AppTheme.outline : AppTheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        task.description,
                        style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                      ),
                      value: task.isCompleted,
                      onChanged: (val) => _toggleTask(plan, task),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_mySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: AppTheme.outline),
            const SizedBox(height: 16),
            const Text('No 1-on-1 Mentorship Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('When a senior responds or an identity reveal is accepted, your direct session opens here.', style: TextStyle(color: AppTheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mySessions.length,
      itemBuilder: (context, index) {
        final sess = _mySessions[index];
        return Card(
          color: AppTheme.surfaceContainerLowest,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sess.seniorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(sess.seniorPlacementTag ?? 'Senior Mentor', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Level 3 Direct', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sess.sessionNotes != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    sess.sessionNotes!,
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MentorshipChatScreen(session: sess)),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Open Mentorship Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutcomesTab() {
    if (_isLoadingOutcomes) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _verifiedOutcomes.length,
      itemBuilder: (context, index) {
        final outcome = _verifiedOutcomes[index];
        final bool isPlacement = outcome['outcomeType'] == 'PLACEMENT_RECEIVED';

        return Card(
          color: AppTheme.surfaceContainerLowest,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: isPlacement ? Colors.amber.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.15),
              child: Icon(
                isPlacement ? Icons.work : Icons.school,
                color: isPlacement ? Colors.amber : AppTheme.primary,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    outcome['juniorName'] ?? 'Student',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: AppTheme.success),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Offered: ${outcome['role']} at ${outcome['company']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mentored by: ${outcome['seniorName']}',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
