class RecordRequest {
  final int sharedRouteId;

  RecordRequest({
    required this.sharedRouteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sharedRouteId': sharedRouteId,
    };
  }

  factory RecordRequest.fromJson(Map<String, dynamic> json) {
    return RecordRequest(
      sharedRouteId: json['sharedRouteId'] ?? 0,
    );
  }
}
