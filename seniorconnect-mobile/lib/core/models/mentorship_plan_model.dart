class MentorshipPlanModel {
  final String id;
  final String juniorId;
  final String juniorName;
  final String? seniorId;
  final String seniorName;
  final String goalTitle;
  final String targetCompany;
  final String targetRole;
  final int durationDays;
  final String status;
  final int progressPercentage;
  final List<PlanTaskItem> tasks;
  final String createdAt;

  MentorshipPlanModel({
    required this.id,
    required this.juniorId,
    required this.juniorName,
    this.seniorId,
    required this.seniorName,
    required this.goalTitle,
    required this.targetCompany,
    required this.targetRole,
    required this.durationDays,
    required this.status,
    required this.progressPercentage,
    required this.tasks,
    required this.createdAt,
  });

  factory MentorshipPlanModel.fromJson(Map<String, dynamic> json) {
    return MentorshipPlanModel(
      id: json['id'] ?? '',
      juniorId: json['juniorId'] ?? '',
      juniorName: json['juniorName'] ?? 'Mentee',
      seniorId: json['seniorId'],
      seniorName: json['seniorName'] ?? 'Senior Mentor',
      goalTitle: json['goalTitle'] ?? '',
      targetCompany: json['targetCompany'] ?? '',
      targetRole: json['targetRole'] ?? 'SDE',
      durationDays: json['durationDays'] ?? 90,
      status: json['status'] ?? 'ACTIVE',
      progressPercentage: json['progressPercentage'] ?? 0,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => PlanTaskItem.fromJson(t))
              .toList() ??
          [],
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlanTaskItem {
  final String id;
  final int weekNumber;
  final String title;
  final String description;
  bool isCompleted;

  PlanTaskItem({
    required this.id,
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.isCompleted,
  });

  factory PlanTaskItem.fromJson(Map<String, dynamic> json) {
    return PlanTaskItem(
      id: json['id'] ?? '',
      weekNumber: json['weekNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
