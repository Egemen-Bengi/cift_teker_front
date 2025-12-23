import 'dart:async';

import 'package:cift_teker_front/formatter/parse_map_data.dart';
import 'package:cift_teker_front/models/requests/sharedRoute_request.dart';
import 'package:cift_teker_front/models/responses/rideHistory_response.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RideDetailMapPage extends StatefulWidget {
  final RideHistoryResponse ride;

  const RideDetailMapPage({super.key, required this.ride});

  @override
  State<RideDetailMapPage> createState() => _RideDetailMapPageState();
}

class _RideDetailMapPageState extends State<RideDetailMapPage> {
  final _mapController = Completer<GoogleMapController>();
  final _parser = MapDataParser();
  final _polylines = <Polyline>{};
  final _markers = <Marker>{};
  final _storage = const FlutterSecureStorage();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  LatLng? _initialPosition;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _loadMapData() {
    final points = _parser.parseMapData(widget.ride.mapData);
    if (points.isEmpty) return;

    _initialPosition = points.first;
    _setRouteAndMarkers(points);

    _mapController.future.then((controller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToRoute(controller, points);
      });
    });
  }

  void _setRouteAndMarkers(List<LatLng> points) {
    _polylines.add(
      Polyline(
        polylineId: PolylineId('ride_${widget.ride.historyId}'),
        points: points,
        width: 6,
        color: Colors.blue.shade700,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    );

    _markers
      ..add(
        _buildMarker(
          points.first,
          'start',
          'Başlangıç',
          BitmapDescriptor.hueGreen,
        ),
      )
      ..add(_buildMarker(points.last, 'end', 'Bitiş', BitmapDescriptor.hueRed));

    setState(() {});
  }

  Marker _buildMarker(LatLng position, String id, String title, double hue) =>
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );

  Future<void> _fitMapToRoute(
    GoogleMapController controller,
    List<LatLng> points,
  ) async {
    final bounds = _getBoundsForPoints(points);
    if (bounds == null) return;

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (e) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
    }
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

  void _openShareDialog() {
    _nameController.clear();
    _descController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Rotayı Paylaş"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Rota Adı"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Açıklama"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);

                          final success = await _shareRoute();

                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }

                          if (context.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Paylaş"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _shareRoute() async {
    try {
      final imageUrl = await _captureAndUploadMap();
      final token = await _storage.read(key: "auth_token");

      if (token == null) throw "Oturum bilgisi bulunamadı.";

      final request = SharedRouteRequest(
        routeName: _nameController.text,
        description: _descController.text,
        historyId: widget.ride.historyId,
        imageUrl: imageUrl,
      );

      await SharedRouteService().saveSharedRoute(request, token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rota başarıyla paylaşıldı!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Paylaşım başarısız: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return false;
  }

  Future<String?> _captureAndUploadMap() async {
    final controller = await _mapController.future;
    final bytes = await controller.takeSnapshot();

    if (bytes == null) return null;

    final ref = FirebaseStorage.instance.ref(
      'route_images/ride_${widget.ride.historyId}_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/png'),
    );

    return snapshot.ref.getDownloadURL();
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String t(int n) => n.toString().padLeft(2, '0');
    return '${t(d.inHours)}:${t(d.inMinutes.remainder(60))}:${t(d.inSeconds.remainder(60))}';
  }

  String _formatDate(DateTime dt) =>
      DateFormat('dd MMMM yyyy HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Sürüş Detayı",
        showAvatar: false,
        actions: [
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _openShareDialog,
                ),
        ],
      ),
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
