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
  final RideHistoryService rideService = RideHistoryService();

  GoogleMapController? mapController;
  LatLng? currentPosition;

  StompClient? stompClient;
  Timer? _timer;

  final List<LatLng> ridePoints = [];
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

    if (!mounted) return;
    setState(() {
      isPageReady = true;
    });
  }

  Future<void> _getToken() async {
    token = await _storage.read(key: "auth_token");

    if ((token == null || token!.isEmpty) && mounted) {
      _show("Token bulunamadı.");
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        // küçük bir bekleme, kullanıcı ayarları açtıysa değişikliğin yansıması için
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) _show("Lütfen konum servislerini açın.");
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) _show("Konum izni reddedildi.");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _show("Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.");
        return;
      }

      // Konumu al
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        currentPosition = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      debugPrint('getUserLocation error: $e');
      // fallback: son bilinen konumu dene
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          setState(() {
            currentPosition = LatLng(last.latitude, last.longitude);
          });
          return;
        }
      } catch (e2) {
        debugPrint('getLastKnownPosition error: $e2');
      }

      if (mounted) _show("Konum alınamadı: $e");
    }
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
          url:
              'https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/ws',
          stompConnectHeaders: {'Authorization': 'Bearer $token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
          onConnect: _onStompConnect,
          onWebSocketError: (err) => debugPrint("WebSocket Hata: $err"),
          onStompError: (frame) =>
              debugPrint("STOMP Hata: ${frame.body}"),
        ),
      );

      stompClient!.activate();
    } catch (e) {
      _show("Sürüş başlatılamadı: $e");
    }
  }

  void _onStompConnect(StompFrame frame) {
    stompClient!.subscribe(
      destination: '/topic/ride/$rideId',
      callback: (frame) {
        debugPrint('Mesaj alındı: ${frame.body}');
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;

      Position pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      LatLng point = LatLng(pos.latitude, pos.longitude);
      ridePoints.add(point);

      if (!mounted) return;
      setState(() {});

      if (mapController != null && mounted) {
        mapController!
            .animateCamera(CameraUpdate.newLatLng(point));
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
    _timer = null;

    await _getToken();
    if (token == null || token!.isEmpty) {
      _show("Token bulunamadı. Sürüş kaydedilemedi.");
      return;
    }

    if (ridePoints.isEmpty) {
      _show("Sürüş verisi bulunamadı.");
      return;
    }

    final mapData = jsonEncode(
      ridePoints
          .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
          .toList(),
    );

    final double distanceKm = calculateDistanceKm(ridePoints);
    final int durationSeconds = ridePoints.length * 5;
    final double averageSpeedKmh =
        calculateAverageSpeed(distanceKm, durationSeconds);

    final RideHistoryRequest req = RideHistoryRequest(
      mapData: mapData,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      averageSpeedKmh: averageSpeedKmh,
      startDateTime:
          DateTime.now().subtract(Duration(seconds: durationSeconds)),
      endDateTime: DateTime.now(),
    );

    try {
      await rideService.saveRideHistory(req, token!);

      stompClient?.deactivate();
      stompClient = null;

      if (!mounted) return;
      setState(() {
        ridePoints.clear();
        rideId = null;
      });

      _show("Sürüş kaydedildi.");
    } catch (e) {
      _show("Hata: $e");
    }
  }

  double calculateDistanceKm(List<LatLng> pts) {
    if (pts.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        pts[i].latitude,
        pts[i].longitude,
        pts[i + 1].latitude,
        pts[i + 1].longitude,
      );
    }
    return totalDistance / 1000.0;
  }

  double calculateAverageSpeed(double km, int sec) =>
      sec == 0 ? 0 : km / (sec / 3600);

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    stompClient?.deactivate();
    mapController?.dispose();

    _timer = null;
    stompClient = null;
    mapController = null;

    super.dispose();
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
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
