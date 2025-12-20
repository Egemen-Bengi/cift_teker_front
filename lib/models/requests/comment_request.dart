class CommentRequest {
  final int sharedRouteId;
  final String content;
  final int? parentCommentId;

  CommentRequest({
    required this.sharedRouteId,
    required this.content,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      "sharedRouteId": sharedRouteId,
      "content": content,
      if (parentCommentId != null) "parentCommentId": parentCommentId,
    };
  }
}
