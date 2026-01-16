class UpdateGroupEventRequest {
  final String? title;
  final String? description;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? startLocation;
  final String? endLocation;
  final int? maxParticipants;
  final String? city;

  UpdateGroupEventRequest({
    this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
    this.startLocation,
    this.endLocation,
    this.maxParticipants,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "startDateTime": startDateTime?.toIso8601String(),
      "endDateTime": endDateTime?.toIso8601String(),
      "startLocation": startLocation,
      "endLocation": endLocation,
      "maxParticipants": maxParticipants,
      "city": city,
    };
  }
}
