class CommentRequest {
  final int routeId;
  final int? sharedRouteId;
  final String content;
  final int? parentCommentId;

  CommentRequest({
    required this.routeId,
    this.sharedRouteId,
    required this.content,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      "routeId": routeId,
      if (sharedRouteId != null) "sharedRouteId": sharedRouteId,
      "content": content,
      if (parentCommentId != null) "parentCommentId": parentCommentId,
    };
  }
}
