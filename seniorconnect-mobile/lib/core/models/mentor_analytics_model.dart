class MentorAnalyticsModel {
  final String mentorId;
  final String mentorName;
  final String email;
  final String branch;
  final String? placementTag;
  final bool isTagVerified;
  final int totalPoints;
  final int trustScore;
  final double averageRating;
  final int totalReviews;
  final int activeMenteesCount;
  final int verifiedPlacementsCount;
  final int totalGuidanceMessagesSent;
  final List<String> earnedBadges;
  final List<MentorshipReviewModel> recentReviews;

  MentorAnalyticsModel({
    required this.mentorId,
    required this.mentorName,
    required this.email,
    required this.branch,
    this.placementTag,
    required this.isTagVerified,
    required this.totalPoints,
    required this.trustScore,
    required this.averageRating,
    required this.totalReviews,
    required this.activeMenteesCount,
    required this.verifiedPlacementsCount,
    required this.totalGuidanceMessagesSent,
    required this.earnedBadges,
    required this.recentReviews,
  });

  factory MentorAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return MentorAnalyticsModel(
      mentorId: json['mentorId'] ?? '',
      mentorName: json['mentorName'] ?? '',
      email: json['email'] ?? '',
      branch: json['branch'] ?? '',
      placementTag: json['placementTag'],
      isTagVerified: json['isTagVerified'] ?? false,
      totalPoints: json['totalPoints'] ?? 0,
      trustScore: json['trustScore'] ?? 85,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: json['totalReviews'] ?? 0,
      activeMenteesCount: json['activeMenteesCount'] ?? 0,
      verifiedPlacementsCount: json['verifiedPlacementsCount'] ?? 0,
      totalGuidanceMessagesSent: json['totalGuidanceMessagesSent'] ?? 0,
      earnedBadges: (json['earnedBadges'] as List<dynamic>?)?.map((b) => b.toString()).toList() ?? [],
      recentReviews: (json['recentReviews'] as List<dynamic>?)
              ?.map((r) => MentorshipReviewModel.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class MentorshipReviewModel {
  final String id;
  final String sessionId;
  final String juniorName;
  final String seniorName;
  final int rating;
  final String? reviewComment;
  final String createdAt;

  MentorshipReviewModel({
    required this.id,
    required this.sessionId,
    required this.juniorName,
    required this.seniorName,
    required this.rating,
    this.reviewComment,
    required this.createdAt,
  });

  factory MentorshipReviewModel.fromJson(Map<String, dynamic> json) {
    return MentorshipReviewModel(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      juniorName: json['juniorName'] ?? 'Mentee',
      seniorName: json['seniorName'] ?? 'Senior Mentor',
      rating: json['rating'] ?? 5,
      reviewComment: json['reviewComment'],
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
