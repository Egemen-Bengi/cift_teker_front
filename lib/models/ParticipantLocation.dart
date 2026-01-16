import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParticipantLocation {
  final int userId;
  final String username;
  final int? rideId;
  final int? groupEventId;
  final LatLng location;
  final DateTime timestamp;
  final double speed;

  ParticipantLocation({
    required this.userId,
    required this.username,
    this.rideId,
    this.groupEventId,
    required this.location,
    required this.timestamp,
    this.speed = 0.0,
  });

  factory ParticipantLocation.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    if (json['timestamp'] is String) {
      parsedTimestamp = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
    } else if (json['timestamp'] is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ParticipantLocation(
      userId: int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      username: json['username'] ?? 'Bilinmeyen Sürücü',
      rideId: json['rideId'] != null
          ? (int.tryParse(json['rideId'].toString()) ?? 0)
          : null,

      groupEventId: json['groupEventId'] != null
          ? (int.tryParse(json['groupEventId'].toString()) ?? 0)
          : null,

      location: LatLng(
        double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
        double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      ),
      timestamp: parsedTimestamp,
      speed: double.tryParse(json['speed']?.toString() ?? '0.0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'rideId': rideId,
      'groupEventId': groupEventId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }
}
