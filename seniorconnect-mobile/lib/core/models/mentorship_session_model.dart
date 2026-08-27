class MentorshipSessionModel {
  final String id;
  final String juniorId;
  final String juniorName;
  final String juniorEmail;
  final String juniorBranch;
  final String seniorId;
  final String seniorName;
  final String seniorEmail;
  final String seniorBranch;
  final String? seniorPlacementTag;
  final String? queryId;
  final String? queryTitle;
  final String? planId;
  final String status;
  final int privacyLevel;
  final String? meetingLink;
  final String? sessionNotes;
  final String? scheduledAt;
  final String createdAt;

  MentorshipSessionModel({
    required this.id,
    required this.juniorId,
    required this.juniorName,
    required this.juniorEmail,
    required this.juniorBranch,
    required this.seniorId,
    required this.seniorName,
    required this.seniorEmail,
    required this.seniorBranch,
    this.seniorPlacementTag,
    this.queryId,
    this.queryTitle,
    this.planId,
    required this.status,
    required this.privacyLevel,
    this.meetingLink,
    this.sessionNotes,
    this.scheduledAt,
    required this.createdAt,
  });

  factory MentorshipSessionModel.fromJson(Map<String, dynamic> json) {
    return MentorshipSessionModel(
      id: json['id'] ?? '',
      juniorId: json['juniorId'] ?? '',
      juniorName: json['juniorName'] ?? 'Junior',
      juniorEmail: json['juniorEmail'] ?? '',
      juniorBranch: json['juniorBranch'] ?? 'Engineering',
      seniorId: json['seniorId'] ?? '',
      seniorName: json['seniorName'] ?? 'Senior Mentor',
      seniorEmail: json['seniorEmail'] ?? '',
      seniorBranch: json['seniorBranch'] ?? 'Engineering',
      seniorPlacementTag: json['seniorPlacementTag'],
      queryId: json['queryId'],
      queryTitle: json['queryTitle'],
      planId: json['planId'],
      status: json['status'] ?? 'ACTIVE',
      privacyLevel: json['privacyLevel'] ?? 3,
      meetingLink: json['meetingLink'],
      sessionNotes: json['sessionNotes'],
      scheduledAt: json['scheduledAt']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class SessionMessageModel {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String messageContent;
  final bool isEncrypted;
  final String createdAt;

  SessionMessageModel({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.messageContent,
    required this.isEncrypted,
    required this.createdAt,
  });

  factory SessionMessageModel.fromJson(Map<String, dynamic> json) {
    return SessionMessageModel(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Member',
      messageContent: json['messageContent'] ?? '',
      isEncrypted: json['isEncrypted'] ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
