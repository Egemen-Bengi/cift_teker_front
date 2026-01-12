import 'dart:async';
import 'package:cift_teker_front/formatter/parse_map_data.dart';
import 'package:cift_teker_front/models/responses/rideHistory_response.dart';
import 'package:cift_teker_front/screens/RideHistory/ride_history_detail_page.dart';
import 'package:cift_teker_front/services/rideHistory_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  final RideHistoryService _service = RideHistoryService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final MapDataParser _parser = MapDataParser();

  List<RideHistoryResponse> _rides = [];
  bool _loading = true;
  String? _error;
  int? _selectedHistoryId;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Oturum bulunamadı. Lütfen tekrar giriş yapın.");
      }
      final rides = await _service.getMyRideHistory(token);

      rides.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      if (mounted) {
        setState(() {
          _rides = rides;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll("Exception: ", "");
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $_error')));
      }
    }
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: "auth_token");
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
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  void _onRideSelected(RideHistoryResponse ride) {
    setState(() {
      _selectedHistoryId = ride.historyId;
    });

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => RideDetailMapPage(ride: ride)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Sürüş Geçmişi"),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadRides(isRefresh: true),
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.35),
          Center(child: Text('Hata: $_error')),
        ],
      );
    }

    if (_rides.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.35),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('Henüz sürüş kaydınız yok.'),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _rides.length,
      itemBuilder: (context, index) {
        final ride = _rides[index];
        final selected = ride.historyId == _selectedHistoryId;

        // Rota noktalarını hesapla
        final points = _parser.parseMapData(ride.mapData);
        final startPoint = points.isNotEmpty
            ? points.first
            : const LatLng(41, 29);

        return GestureDetector(
          onTap: () => _onRideSelected(ride),
          child: Card(
            color: selected ? Colors.blue.shade50 : null,
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bilgi Satırı (Mesafe, Süre, Hız)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${ride.distanceKm.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDate(ride.startDateTime),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Süre ve Hız
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(_formatDuration(ride.durationSeconds)),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.speed,
                                  size: 14,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${ride.averageSpeedKmh.toStringAsFixed(1)} km/h',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Grup Sürüşü etiketi
                            if (ride.groupEventId != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Grup Sürüşü',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade600),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 120,
                      child: AbsorbPointer(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: startPoint,
                            zoom: points.length > 1 ? 13 : 8,
                          ),
                          polylines: {
                            if (points.isNotEmpty)
                              Polyline(
                                polylineId: PolylineId(
                                  "mini_${ride.historyId}",
                                ),
                                points: points,
                                width: 4,
                                color: Colors.blue,
                              ),
                          },
                          markers: {
                            if (points.isNotEmpty)
                              Marker(
                                markerId: MarkerId("m_${ride.historyId}"),
                                position: startPoint,
                                icon: BitmapDescriptor.defaultMarker,
                              ),
                          },
                          liteModeEnabled: true,
                          mapToolbarEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
