import 'dart:async';
import 'package:cift_teker_front/formatter/parse_map_data.dart';
import 'package:cift_teker_front/models/responses/rideHistory_response.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';

class RideDetailMapPage extends StatefulWidget {
  final RideHistoryResponse ride;

  const RideDetailMapPage({super.key, required this.ride});

  @override
  State<RideDetailMapPage> createState() => _RideDetailMapPageState();
}

class _RideDetailMapPageState extends State<RideDetailMapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final MapDataParser _parser = MapDataParser();
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  void _loadMapData() {
    final points = _parser.parseMapData(widget.ride.mapData);

    if (points.isNotEmpty) {
      _initialPosition = points.first;
      _setRouteAndMarkers(points);

      _mapController.future.then((controller) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapToRoute(controller, points);
        });
      });
    }
  }

  void _setRouteAndMarkers(List<LatLng> points) {
    if (points.isEmpty) return;

    _polylines.add(
      Polyline(
        polylineId: PolylineId('ride_${widget.ride.historyId}'),
        points: points,
        width: 6,
        color: Colors.blue.shade700,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
      ),
    );

    // Başlangıç ve Bitiş Marker'ları
    final start = points.first;
    final end = points.last;

    _markers.add(
      Marker(
        markerId: const MarkerId('start_point'),
        position: start,
        infoWindow: const InfoWindow(title: 'Başlangıç'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    if (start != end) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end_point'),
          position: end,
          infoWindow: const InfoWindow(title: 'Bitiş'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {});
  }

  LatLngBounds? _getBoundsForPoints(List<LatLng> points) {
    if (points.isEmpty) return null;
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final p in points) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Future<void> _fitMapToRoute(
    GoogleMapController controller,
    List<LatLng> points,
  ) async {
    final bounds = _getBoundsForPoints(points);
    if (bounds == null) return;

    try {
      final camUpdate = CameraUpdate.newLatLngBounds(bounds, 60);
      await controller.animateCamera(camUpdate);
    } catch (e) {
      if (points.isNotEmpty) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMMM yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    return Scaffold(
      appBar: CustomAppBar(title: "Sürüş Detayı"),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition ?? const LatLng(41.0, 29.0),
                zoom: 12,
              ),
              onMapCreated: (GoogleMapController controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              markers: _markers,
              polylines: _polylines,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    icon: Icons.route,
                    label: "Mesafe",
                    value: "${ride.distanceKm.toStringAsFixed(2)} km",
                    color: Colors.blue.shade700,
                  ),
                  _buildInfoRow(
                    icon: Icons.timer,
                    label: "Süre",
                    value: _formatDuration(ride.durationSeconds),
                    color: Colors.red.shade700,
                  ),
                  _buildInfoRow(
                    icon: Icons.speed,
                    label: "Ortalama Hız",
                    value: "${ride.averageSpeedKmh.toStringAsFixed(1)} km/h",
                    color: Colors.green.shade700,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: "Tarih ve Saat",
                    value: _formatDate(ride.startDateTime),
                    color: Colors.grey.shade700,
                  ),
                  if (ride.groupEventId != null)
                    _buildInfoRow(
                      icon: Icons.people,
                      label: "Etkinlik",
                      value: "Grup Sürüşü (ID: ${ride.groupEventId})",
                      color: Colors.purple.shade700,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
