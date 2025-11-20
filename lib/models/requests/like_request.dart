import 'dart:ffi';

class LikeRequest {
  final Long sharedRouteId;

  LikeRequest({required this.sharedRouteId});

  Map<String, dynamic> toJson() {
    return {
      'sharedRouteId': sharedRouteId,
    };
  }
}
