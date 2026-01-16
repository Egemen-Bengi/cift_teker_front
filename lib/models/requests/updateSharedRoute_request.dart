class UpdateSharedRouteRequest {
  final String routeName;
  final String? description;
  final String? imageUrl;

  UpdateSharedRouteRequest({
    required this.routeName,
    this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "routeName": routeName,
      "description": description,
      "imageUrl": imageUrl,
    };
  }
}
