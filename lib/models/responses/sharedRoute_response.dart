class SharedRouteResponse {
  final int sharedRouteId;
  final String routeName;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final int userId;
  final String username;
  final int historyId;

  SharedRouteResponse({
    required this.sharedRouteId,
    required this.routeName,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.userId,
    required this.username,
    required this.historyId,
  });

  factory SharedRouteResponse.fromJson(Map<String, dynamic> json) {
    return SharedRouteResponse(
      sharedRouteId: json["sharedRouteId"],
      routeName: json["routeName"],
      description: json["description"],
      imageUrl: json["imageUrl"],
      createdAt: DateTime.parse(json["createdAt"]),
      userId: json["userId"],
      username: json["username"],
      historyId: json["historyId"],
    );
  }
}
