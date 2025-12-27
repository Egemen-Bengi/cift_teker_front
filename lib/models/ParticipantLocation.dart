import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParticipantLocation {
  final int userId;
  final String username;
  final LatLng location;
  final DateTime timestamp;
  final double speed;

  ParticipantLocation({
    required this.userId,
    required this.username,
    required this.location,
    required this.timestamp,
    this.speed = 0.0,
  });

  factory ParticipantLocation.fromJson(Map<String, dynamic> json) {
    return ParticipantLocation(
      userId: json['userId'] is int
          ? json['userId']
          : int.parse(json['userId'].toString()),
      username: json['username'] ?? 'Unknown',
      location: LatLng(
        (json['latitude'] is double)
            ? json['latitude']
            : double.parse(json['latitude'].toString()),
        (json['longitude'] is double)
            ? json['longitude']
            : double.parse(json['longitude'].toString()),
      ),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      speed: (json['speed'] is double)
          ? json['speed']
          : double.parse((json['speed'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
    };
  }
}
