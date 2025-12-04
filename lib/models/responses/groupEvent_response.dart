class GroupEventResponse {
  final int groupEventId;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String status;
  final String startLocation;
  final String endLocation;
  final int maxParticipants;
  final int userId;
  final String? city;

  GroupEventResponse({
    required this.groupEventId,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
    required this.startLocation,
    required this.endLocation,
    required this.maxParticipants,
    required this.userId,
    this.city,
  });

  factory GroupEventResponse.fromJson(Map<String, dynamic> json) {
    return GroupEventResponse(
      groupEventId: json["groupEventId"],
      title: json["title"],
      description: json["description"],
      startDateTime: DateTime.parse(json["startDateTime"]),
      endDateTime: DateTime.parse(json["endDateTime"]),
      status: json["status"],
      startLocation: json["startLocation"],
      endLocation: json["endLocation"],
      maxParticipants: json["maxParticipants"],
      userId: json["userId"],
      city: json["city"],
    );
  }
}
