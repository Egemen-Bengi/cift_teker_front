class GroupEventRequest {
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String startLocation;
  final String endLocation;
  final int maxParticipants;
  final String city;

  GroupEventRequest({
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.startLocation,
    required this.endLocation,
    required this.maxParticipants,
    required this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "startDateTime": startDateTime.toIso8601String(),
      "endDateTime": endDateTime.toIso8601String(),
      "startLocation": startLocation,
      "endLocation": endLocation,
      "maxParticipants": maxParticipants,
      "city": city,
    };
  }
}
