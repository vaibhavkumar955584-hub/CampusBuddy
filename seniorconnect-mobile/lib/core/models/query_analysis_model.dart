class QueryAnalysisModel {
  final String intent;
  final String domain;
  final List<String> skills;
  final String? targetCompany;
  final String? targetRole;
  final int timelineDays;
  final String urgency;
  final String experienceLevel;
  final List<SimilarQuestionItem> similarQuestions;
  final List<RecommendedMentorItem> recommendedMentors;

  QueryAnalysisModel({
    required this.intent,
    required this.domain,
    required this.skills,
    this.targetCompany,
    this.targetRole,
    required this.timelineDays,
    required this.urgency,
    required this.experienceLevel,
    required this.similarQuestions,
    required this.recommendedMentors,
  });

  factory QueryAnalysisModel.fromJson(Map<String, dynamic> json) {
    return QueryAnalysisModel(
      intent: json['intent'] ?? 'PLACEMENT_PREPARATION',
      domain: json['domain'] ?? 'SOFTWARE_ENGINEERING',
      skills: (json['skills'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      targetCompany: json['targetCompany'],
      targetRole: json['targetRole'],
      timelineDays: json['timelineDays'] ?? 90,
      urgency: json['urgency'] ?? 'MEDIUM',
      experienceLevel: json['experienceLevel'] ?? 'INTERMEDIATE',
      similarQuestions: (json['similarQuestions'] as List<dynamic>?)
              ?.map((q) => SimilarQuestionItem.fromJson(q))
              .toList() ??
          [],
      recommendedMentors: (json['recommendedMentors'] as List<dynamic>?)
              ?.map((m) => RecommendedMentorItem.fromJson(m))
              .toList() ??
          [],
    );
  }
}

class SimilarQuestionItem {
  final String id;
  final String title;
  final int similarityScore;
  final int responsesCount;
  final String answeredBy;

  SimilarQuestionItem({
    required this.id,
    required this.title,
    required this.similarityScore,
    required this.responsesCount,
    required this.answeredBy,
  });

  factory SimilarQuestionItem.fromJson(Map<String, dynamic> json) {
    return SimilarQuestionItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      similarityScore: (json['similarityScore'] as num?)?.toInt() ?? 80,
      responsesCount: json['responsesCount'] ?? 0,
      answeredBy: json['answeredBy'] ?? 'Senior Mentor',
    );
  }
}

class RecommendedMentorItem {
  final String mentorId;
  final String mentorName;
  final String currentCompany;
  final String branch;
  final int matchPercentage;
  final int studentsHelped;
  final List<String> matchedSkills;
  final bool isVerified;

  RecommendedMentorItem({
    required this.mentorId,
    required this.mentorName,
    required this.currentCompany,
    required this.branch,
    required this.matchPercentage,
    required this.studentsHelped,
    required this.matchedSkills,
    required this.isVerified,
  });

  factory RecommendedMentorItem.fromJson(Map<String, dynamic> json) {
    return RecommendedMentorItem(
      mentorId: json['mentorId'] ?? '',
      mentorName: json['mentorName'] ?? '',
      currentCompany: json['currentCompany'] ?? 'Mentor',
      branch: json['branch'] ?? '',
      matchPercentage: json['matchPercentage'] ?? 85,
      studentsHelped: json['studentsHelped'] ?? 10,
      matchedSkills: (json['matchedSkills'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
      isVerified: json['isVerified'] ?? false,
    );
  }
}
