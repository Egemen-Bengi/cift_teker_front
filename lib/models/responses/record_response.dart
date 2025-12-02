class RecordResponse {
  final int recordId;
  final int userId;
  final int sharedRouteId;
  final DateTime createdAt;

  RecordResponse({
    required this.recordId,
    required this.userId,
    required this.sharedRouteId,
    required this.createdAt,
  });

  factory RecordResponse.fromJson(Map<String, dynamic> json) {
    return RecordResponse(
      recordId: json['recordId'],
      userId: json['userId'],
      sharedRouteId: json['sharedRouteId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
