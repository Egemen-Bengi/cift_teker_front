class GroupEventResponse {
  final int groupEventId;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String startLocation;
  final String endLocation;
  final int maxParticipants;
  final int userId;
  final String username;
  final String? city;
  final bool isJoined;

  GroupEventResponse({
    required this.groupEventId,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.startLocation,
    required this.endLocation,
    required this.maxParticipants,
    required this.userId,
    required this.username,
    this.city,
    this.isJoined = false,
  });

  factory GroupEventResponse.fromJson(Map<String, dynamic> json) {
    return GroupEventResponse(
      groupEventId: json["groupEventId"],
      title: json["title"],
      description: json["description"],
      startDateTime: DateTime.parse(json["startDateTime"]),
      endDateTime: DateTime.parse(json["endDateTime"]),
      startLocation: json["startLocation"],
      endLocation: json["endLocation"],
      maxParticipants: json["maxParticipants"],
      userId: json["userId"],
      username: json["username"],
      city: json["city"],
      isJoined: json["isJoined"] ?? false,
    );
  }
}
