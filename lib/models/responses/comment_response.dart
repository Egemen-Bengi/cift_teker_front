class CommentResponse {
  final int commentId;
  final String content;
  final int userId;
  final String username;
  final int? routeId;
  final int? sharedRouteId;
  final int? parentCommentId;
  final DateTime createdAt;

  CommentResponse({
    required this.commentId,
    required this.content,
    required this.userId,
    required this.username,
    this.routeId,
    this.sharedRouteId,
    this.parentCommentId,
    required this.createdAt,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) {
    return CommentResponse(
      commentId: json["commentId"],
      content: json["content"],
      userId: json["userId"],
      username: json["username"],
      routeId: json["routeId"],
      sharedRouteId: json["sharedRouteId"],
      parentCommentId: json["parentCommentId"],
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}
