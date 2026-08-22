class AnswerModel {
  final String id;
  final String seniorId;
  final String seniorName;
  final String? seniorBranch;
  final String? placementTag;
  final bool isTagVerified;
  final String content;
  final bool isAcceptedAnswer;
  final String createdAt;

  AnswerModel({
    required this.id,
    required this.seniorId,
    required this.seniorName,
    this.seniorBranch,
    this.placementTag,
    required this.isTagVerified,
    required this.content,
    required this.isAcceptedAnswer,
    required this.createdAt,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] ?? '',
      seniorId: json['seniorId'] ?? '',
      seniorName: json['seniorName'] ?? 'Senior Mentor',
      seniorBranch: json['seniorBranch'],
      placementTag: json['placementTag'],
      isTagVerified: json['isTagVerified'] ?? false,
      content: json['content'] ?? '',
      isAcceptedAnswer: json['isAcceptedAnswer'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class QueryModel {
  final String id;
  final String title;
  final String content;
  final String? tags;
  final bool isAnonymousDisplay;
  final String? juniorId;
  final String juniorName;
  final String? juniorBranch;
  final int? juniorSemester;
  final bool identityRevealedToViewer;
  final String status;
  final int responsesCount;
  final List<AnswerModel> responses;
  final String createdAt;

  QueryModel({
    required this.id,
    required this.title,
    required this.content,
    this.tags,
    required this.isAnonymousDisplay,
    this.juniorId,
    required this.juniorName,
    this.juniorBranch,
    this.juniorSemester,
    required this.identityRevealedToViewer,
    required this.status,
    required this.responsesCount,
    required this.responses,
    required this.createdAt,
  });

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    var rawResponses = json['responses'] as List<dynamic>?;
    List<AnswerModel> parsedResponses = [];
    if (rawResponses != null) {
      parsedResponses = rawResponses.map((r) => AnswerModel.fromJson(r)).toList();
    }

    return QueryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: json['tags'],
      isAnonymousDisplay: json['isAnonymousDisplay'] ?? true,
      juniorId: json['juniorId'],
      juniorName: json['juniorName'] ?? 'Anonymous Junior',
      juniorBranch: json['juniorBranch'],
      juniorSemester: json['juniorSemester'],
      identityRevealedToViewer: json['identityRevealedToViewer'] ?? false,
      status: json['status'] ?? 'OPEN',
      responsesCount: json['responsesCount'] ?? 0,
      responses: parsedResponses,
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool get isResolved => status == 'RESOLVED';
  bool get isClosed => status == 'CLOSED';
}
