class RatingResponse {
  final int ratingId;
  final double rating;
  final int userId;
  final int sharedRouteId;
  final String createdAt;

  RatingResponse({
    required this.ratingId,
    required this.rating,
    required this.userId,
    required this.sharedRouteId,
    required this.createdAt,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      ratingId: json["ratingId"],
      rating: (json["rating"] as num).toDouble(),
      userId: json["userId"],
      sharedRouteId: json["sharedRouteId"],
      createdAt: json["createdAt"],
    );
  }
}
