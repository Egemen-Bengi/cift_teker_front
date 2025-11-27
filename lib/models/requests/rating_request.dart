class RatingRequest {
  final int sharedRouteId;
  final double rating;

  RatingRequest({
    required this.sharedRouteId,
    required this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      "sharedRouteId": sharedRouteId,
      "rating": rating,
    };
  }
}
