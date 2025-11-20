class RideHistoryRequest {
  final String mapData;
  final double distanceKm;
  final int durationSeconds;
  final double averageSpeedKmh;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int? groupEventId;

  RideHistoryRequest({
    required this.mapData,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.startDateTime,
    required this.endDateTime,
    this.groupEventId,
  });

  Map<String, dynamic> toJson() {
    return {
      "mapData": mapData,
      "distanceKm": distanceKm,
      "durationSeconds": durationSeconds,
      "averageSpeedKmh": averageSpeedKmh,
      "startDateTime": startDateTime.toIso8601String(),
      "endDateTime": endDateTime.toIso8601String(),
      if (groupEventId != null) "groupEventId": groupEventId,
    };
  }
}
