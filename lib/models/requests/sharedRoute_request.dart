class SharedRouteRequest {
  final String routeName;
  final int historyId;
  final String? description;
  final String? imageUrl;

  SharedRouteRequest({
    required this.routeName,
    required this.historyId,
    this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "routeName": routeName,
      "historyId": historyId,
      if (description != null) "description": description,
      if (imageUrl != null) "imageUrl": imageUrl,
    };
  }
}
