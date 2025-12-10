import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDataParser {
  List<LatLng> parseMapData(String? mapData) {
    if (mapData == null || mapData.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(mapData);

      if (decoded is! List) {
        return [];
      }

      return decoded.map<LatLng>((item) {
        final latitude = (item['latitude'] as num).toDouble();
        final longitude = (item['longitude'] as num).toDouble();

        return LatLng(latitude, longitude);
      }).toList();
    } catch (e) {
      print("Map parse error: $e");
      return [];
    }
  }
}
