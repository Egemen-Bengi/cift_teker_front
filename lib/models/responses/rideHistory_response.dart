class RideHistoryResponse {
  final int historyId;
  final String mapData;
  final double distanceKm;
  final int durationSeconds;
  final double averageSpeedKmh;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int userId;
  final int? groupEventId; // ride event her zaman bir group evente bağlı olmayabilir
  RideHistoryResponse({
    required this.historyId,
    required this.mapData,
    required this.distanceKm,
    required this.durationSeconds,
    required this.averageSpeedKmh,
    required this.startDateTime,
    required this.endDateTime,
    required this.userId,
    this.groupEventId,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RideHistoryResponse(
      historyId: json['historyId'],
      mapData: json['mapData'],
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationSeconds: json['durationSeconds'],
      averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
      startDateTime: DateTime.parse(json['startDateTime']),
      endDateTime: DateTime.parse(json['endDateTime']),
      userId: json['userId'],
      groupEventId: json['groupEventId'], // null gelebilir
    );
  }
}
