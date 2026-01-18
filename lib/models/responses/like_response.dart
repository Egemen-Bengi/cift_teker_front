class LikeResponse {
  final int likeId;
  final int userId;
  final String username;
  final String? profileImage;
  final int sharedRouteId;
  final DateTime createdAt;

  LikeResponse({
    required this.likeId,
    required this.userId,
    required this.username,
    required this.sharedRouteId,
    required this.createdAt,
    this.profileImage,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      likeId: json['likeId'],
      userId: json['userId'],
      username: json['username'],
      sharedRouteId: json['sharedRouteId'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
