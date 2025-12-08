import 'dart:async';
import 'dart:convert';

import 'package:cift_teker_front/services/rideHistory_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/requests/rideHistory_request.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  RideHistoryService rideService = RideHistoryService();

  GoogleMapController? mapController;
  LatLng? currentPosition;

  StompClient? stompClient;
  Timer? _timer;

  List<LatLng> ridePoints = [];
  int? rideId;

  bool isPageReady = false;

  String? token;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _getToken();
    await _getUserLocation();
    setState(() {
      isPageReady = true;
    });
  }

  Future<void> _getToken() async {
    token = await _storage.read(key: "auth_token");

    if (token == null || token!.isEmpty) {
      _show("Token bulunamadı.");
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition();

    setState(() {
      currentPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  Future<void> _startRide() async {
    if (token == null || token!.isEmpty) {
      await _getToken();
      if (token == null || token!.isEmpty) return;
    }

    if (currentPosition == null) await _getUserLocation();

    try {
      rideId = await rideService.startRide(token!);
      if (rideId == null) {
        _show("Ride ID alınamadı.");
        return;
      }

      stompClient = StompClient(
        config: StompConfig.sockJS(
          url: 'https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/ws',
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          onConnect: _onStompConnect,
          onWebSocketError: (err) => print("WebSocket Hata: $err"),
          onStompError: (frame) => print("STOMP Hata: ${frame.body}"),
        ),
      );

      stompClient!.activate();
    } catch (e) {
      _show("Sürüş başlatılamadı: $e");
    }
  }

  void _onStompConnect(StompFrame frame) {
    print('STOMP Bağlantısı başarılı!');

    stompClient!.subscribe(
      destination: '/topic/ride/$rideId',
      callback: (StompFrame frame) {
        print('Mesaj alındı: ${frame.body}');
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      Position pos = await Geolocator.getCurrentPosition();
      LatLng point = LatLng(pos.latitude, pos.longitude);
      ridePoints.add(point);

      setState(() {});

      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(point));
      }

      stompClient?.send(
        destination: "/app/ride/$rideId/location",
        body: jsonEncode({
          "latitude": point.latitude,
          "longitude": point.longitude,
        }),
      );
    });
  }

  Future<void> _stopRide() async {
    _timer?.cancel();

    if (ridePoints.isEmpty) {
      _show("Sürüş verisi bulunamadı.");
      return;
    }

    String mapData = jsonEncode(
      ridePoints
          .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
          .toList(),
    );

    double distanceKm = calculateDistanceKm(ridePoints);
    int durationSeconds = ridePoints.length * 5;
    double averageSpeedKmh = calculateAverageSpeed(distanceKm, durationSeconds);
    DateTime startDateTime = DateTime.now().subtract(
      Duration(seconds: durationSeconds),
    );

    RideHistoryRequest req = RideHistoryRequest(
      mapData: mapData,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averageSpeedKmh: averageSpeedKmh,
      startDateTime: startDateTime,
      endDateTime: DateTime.now(),
    );

    try {
      await rideService.saveRideHistory(req, token!);

      stompClient?.deactivate();
      stompClient = null;

      setState(() {
        ridePoints.clear();
        rideId = null;
      });

      _show("Sürüş kaydedildi.");
    } catch (e) {
      _show("Hata: $e");
    }
  }

  double calculateDistanceKm(List<LatLng> pts) => pts.length * 0.05;

  double calculateAverageSpeed(double km, int sec) =>
      sec == 0 ? 0 : km / (sec / 3600);

  void _show(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Sürüş"),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => mapController = c,
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: currentPosition!,
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("ride"),
                      points: ridePoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
                ),

                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: (!isPageReady)
                        ? null
                        : (rideId == null ? _startRide : _stopRide),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      !isPageReady
                          ? "Yükleniyor..."
                          : (rideId == null
                                ? "Bireysel Sürüşü Başlat"
                                : "Sürüşü Bitir"),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
