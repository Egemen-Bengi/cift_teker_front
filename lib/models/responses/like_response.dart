class LikeResponse {
  final int likeId;
  final int userId;
  final int sharedRouteId;
  final DateTime createdAt;

  LikeResponse({
    required this.likeId,
    required this.userId,
    required this.sharedRouteId,
    required this.createdAt,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      likeId: json['likeId'],
      userId: json['userId'],
      sharedRouteId: json['sharedRouteId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
