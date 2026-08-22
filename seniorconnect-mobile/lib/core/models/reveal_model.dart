class RevealModel {
  final String id;
  final String queryId;
  final String queryTitle;
  final String seniorId;
  final String seniorName;
  final String? juniorId;
  final String juniorName;
  final String status;
  final String createdAt;
  final String? resolvedAt;

  RevealModel({
    required this.id,
    required this.queryId,
    required this.queryTitle,
    required this.seniorId,
    required this.seniorName,
    this.juniorId,
    required this.juniorName,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory RevealModel.fromJson(Map<String, dynamic> json) {
    return RevealModel(
      id: json['id'] ?? '',
      queryId: json['queryId'] ?? '',
      queryTitle: json['queryTitle'] ?? '',
      seniorId: json['seniorId'] ?? '',
      seniorName: json['seniorName'] ?? 'Senior Mentor',
      juniorId: json['juniorId'],
      juniorName: json['juniorName'] ?? 'Anonymous Junior',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? '',
      resolvedAt: json['resolvedAt'],
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
}
