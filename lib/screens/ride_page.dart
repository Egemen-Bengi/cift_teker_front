import 'dart:async';
import 'dart:convert';

import 'package:cift_teker_front/models/ParticipantLocation.dart';
import 'package:cift_teker_front/services/rideHistory_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/requests/rideHistory_request.dart';

class RidePage extends StatefulWidget {
  final int? groupEventId;
  const RidePage({super.key, this.groupEventId});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final RideHistoryService _rideService = RideHistoryService();

  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  StompClient? _stompClient;
  Timer? _timer;

  final List<LatLng> _ridePoints = [];
  final Map<int, ParticipantLocation> _participantLocations = {};
  final Set<Marker> _markers = {};

  int? _rideId;
  int? _userId;
  bool _isGroupRide = false;
  bool _isRideStarted = false;
  bool _isPageReady = false;
  bool _isConnecting = false;
  String? _token;

  int _elapsedSeconds = 0;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _isGroupRide = widget.groupEventId != null;
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _getToken();
    await _getUserLocation();
    await _getUserIdFromToken();

    if (!mounted) return;
    setState(() {
      _isPageReady = true;
    });
  }

  Future<void> _getUserIdFromToken() async {
    final parts = _token!.split('.');
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    _userId = payload["id"];
  }

  Future<void> _getToken() async {
    _token = await _storage.read(key: "auth_token");

    if ((_token == null || _token!.isEmpty) && mounted) {
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
        if (mounted)
          _show("Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.");
        return;
      }

      // Konumu al
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      debugPrint('getUserLocation error: $e');
      // fallback: son bilinen konumu dene
      try {
        final Position? last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          setState(() {
            _currentPosition = LatLng(last.latitude, last.longitude);
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
    if (_token == null || _token!.isEmpty) {
      await _getToken();
      if (_token == null || _token!.isEmpty) return;
    }

    if (_currentPosition == null) await _getUserLocation();

    setState(() => _isConnecting = true);

    try {
      final int? rideId = await _rideService.startRide(
        _token!,
        groupEventId: widget.groupEventId,
      );

      if (rideId == null) {
        if (mounted) _show("Sürüş başlatılamadı");
        setState(() => _isConnecting = false);
        return;
      }

      _isGroupRide = widget.groupEventId != null;

      setState(() {
        _rideId = rideId;
        _isRideStarted = true;
      });

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: 'https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/ws',
          stompConnectHeaders: {'Authorization': 'Bearer $_token'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
          onConnect: _onStompConnect,
          onWebSocketError: (err) => debugPrint("WebSocket Hata: $err"),
          onStompError: (frame) => debugPrint("STOMP Hata: ${frame.body}"),
        ),
      );

      _stompClient!.activate();
      if (mounted) {
        _show(
          _isGroupRide ? "Grup sürüşü başladı!" : "Bireysel sürüş başladı!",
        );
      }
    } catch (e) {
      _show("Sürüş başlatılamadı: $e");
      setState(() => _isConnecting = false);
    }
  }

  void _onStompConnect(StompFrame frame) {
    debugPrint("STOMP Bağlantısı Başarılı");

    if (!mounted) return;

    if (_isGroupRide && widget.groupEventId != null) {
      _stompClient!.subscribe(
        destination: '/topic/group/${widget.groupEventId}',
        callback: (frame) {
          _handleLocationMessage(frame.body ?? "");
        },
      );
      debugPrint("Subscribed to: /topic/group/${widget.groupEventId}");
    } else {
      if (_rideId != null) {
        _stompClient!.subscribe(
          destination: '/topic/ride/$_rideId',
          callback: (frame) {
            _handleLocationMessage(frame.body ?? "");
          },
        );
        debugPrint("Subscribed to: /topic/ride/$_rideId");
      }
    }

    _startLocationUpdates();

    setState(() => _isConnecting = false);
  }

  void _handleLocationMessage(String messageBody) {
    if (messageBody.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(messageBody);
      final ParticipantLocation location = ParticipantLocation.fromJson(data);

      if (!mounted) return;

      setState(() {
        _participantLocations[location.userId] = location;
        _updateMarkers();
      });

      debugPrint(
        "Konum alındı - Kullanıcı: ${location.username}, Hız: ${location.speed.toStringAsFixed(1)} km/h",
      );
    } catch (e) {
      debugPrint("Konum verisi parse hatası: $e");
    }
  }

  Future<void> _sendCurrentLocation() async {
    if (!mounted || _stompClient == null) return;

    try {
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      final LatLng currentPos = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentPosition = currentPos;
      });

      _ridePoints.add(currentPos);
      _totalDistance = _calculateDistanceKm(_ridePoints);

      _currentSpeed = pos.speed * 3.6;
      _elapsedSeconds += 5;

      if (_mapController != null && mounted) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(currentPos));
      }

      setState(() {});

      // Backend'ye konum gönder
      final String payload = jsonEncode({
        "userId": _userId,
        "rideId": _rideId,
        "latitude": currentPos.latitude,
        "longitude": currentPos.longitude,
        "speed": _currentSpeed,
        "timestamp": DateTime.now().toIso8601String(),
      });

      _stompClient!.send(destination: "/app/sendLocation", body: payload);

      debugPrint(
        "Konum gönderildi: $currentPos, Hız: ${_currentSpeed.toStringAsFixed(2)} km/h",
      );
    } catch (e) {
      debugPrint("Konum güncelleme hatası: $e");
    }
  }

  void _startLocationUpdates() {
    _sendCurrentLocation();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _sendCurrentLocation();
    });
  }

  Future<void> _stopRide() async {
    _timer?.cancel();
    _timer = null;

    if (_token == null || _token!.isEmpty) {
      _show("Token bulunamadı");
      return;
    }

    setState(() => _isConnecting = true);

    try {
      _stompClient?.deactivate();
      _stompClient = null;

      if (_isGroupRide) {
        if (_ridePoints.isEmpty) {
          _show("Sürüş verisi bulunamadı");
          return;
        }

        final List<LatLng> filteredPoints = <LatLng>[];
        for (int i = 0; i < _ridePoints.length; i += 10) {
          filteredPoints.add(_ridePoints[i]);
        }

        if (_ridePoints.isNotEmpty &&
            (filteredPoints.isEmpty ||
                _ridePoints.last != filteredPoints.last)) {
          filteredPoints.add(_ridePoints.last);
        }

        final String mapData = jsonEncode(
          filteredPoints
              .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
              .toList(),
        );

        debugPrint(
          "MapData size: ${mapData.length} bytes, Points: ${_ridePoints.length} -> ${filteredPoints.length}",
        );

        final double averageSpeed = _calculateAverageSpeed(
          _totalDistance,
          _elapsedSeconds,
        );

        final RideHistoryRequest request = RideHistoryRequest(
          mapData: mapData,
          distanceKm: _totalDistance,
          durationSeconds: _elapsedSeconds,
          averageSpeedKmh: averageSpeed,
          startDateTime: DateTime.now().subtract(
            Duration(seconds: _elapsedSeconds),
          ),
          endDateTime: DateTime.now(),
          groupEventId: widget.groupEventId,
        );

        await _rideService.saveRideHistory(request, _token!);

        if (!mounted) return;
        setState(() {
          _participantLocations.clear();
          _updateMarkers();
          _ridePoints.clear();
          _rideId = null;
          _isRideStarted = false;
          _elapsedSeconds = 0;
          _totalDistance = 0.0;
          _currentSpeed = 0.0;
        });
        if (mounted) {
          _show("Grup sürüşü tamamlandı");
        }
      } else {
        if (_ridePoints.isEmpty) {
          if (mounted) _show("Sürüş verisi bulunamadı");
          setState(() => _isConnecting = false);
          return;
        }

        final List<LatLng> filteredPoints = <LatLng>[];
        for (int i = 0; i < _ridePoints.length; i += 10) {
          filteredPoints.add(_ridePoints[i]);
        }

        if (_ridePoints.isNotEmpty &&
            (filteredPoints.isEmpty ||
                _ridePoints.last != filteredPoints.last)) {
          filteredPoints.add(_ridePoints.last);
        }

        final String mapData = jsonEncode(
          filteredPoints
              .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
              .toList(),
        );

        debugPrint(
          "MapData size: ${mapData.length} bytes, Points: ${_ridePoints.length} -> ${filteredPoints.length}",
        );

        final double averageSpeed = _calculateAverageSpeed(
          _totalDistance,
          _elapsedSeconds,
        );

        final RideHistoryRequest request = RideHistoryRequest(
          mapData: mapData,
          distanceKm: _totalDistance,
          durationSeconds: _elapsedSeconds,
          averageSpeedKmh: averageSpeed,
          startDateTime: DateTime.now().subtract(
            Duration(seconds: _elapsedSeconds),
          ),
          endDateTime: DateTime.now(),
        );

        await _rideService.saveRideHistory(request, _token!);

        if (!mounted) return;
        setState(() {
          _ridePoints.clear();
          _rideId = null;
          _isRideStarted = false;
          _elapsedSeconds = 0;
          _totalDistance = 0.0;
          _currentSpeed = 0.0;
        });

        if (mounted) {
          _show(
            "Sürüş kaydedildi - Mesafe: ${_totalDistance.toStringAsFixed(2)} km",
          );
        }
      }
    } catch (e) {
      debugPrint("Sürüş durdurma hatası: $e");
      if (mounted) _show("Hata: $e");
    }

    setState(() => _isConnecting = false);
  }

  double _calculateDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance / 1000.0;
  }

  double _calculateAverageSpeed(double km, int seconds) {
    if (seconds == 0) return 0.0;
    return km / (seconds / 3600);
  }

  void _updateMarkers() {
    _markers.clear();

    for (final entry in _participantLocations.entries) {
      final location = entry.value;
      _markers.add(
        Marker(
          markerId: MarkerId('participant_${location.userId}'),
          position: location.location,
          infoWindow: InfoWindow(
            title: location.username,
            snippet: 'Hız: ${location.speed.toStringAsFixed(1)} km/h',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_user'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Benim Konumum'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stompClient?.deactivate();
    _mapController?.dispose();

    _timer = null;
    _stompClient = null;
    _mapController = null;
    _ridePoints.clear();
    _participantLocations.clear();
    _markers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isGroupRide ? "Grup Sürüşü" : "Bireysel Sürüş",
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => _mapController = c,
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("ride"),
                      points: _ridePoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
                  markers: _markers,
                ),

                // Üst bilgi paneli
                if (_isRideStarted && _isGroupRide)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Katılımcılar: ${_participantLocations.length + 1}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isConnecting || !_isPageReady)
                          ? null
                          : (_isRideStarted ? _stopRide : _startRide),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRideStarted
                            ? Colors.red
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        !_isPageReady
                            ? "Yükleniyor..."
                            : _isConnecting
                            ? "Bağlanıyor..."
                            : (_isRideStarted
                                  ? "Sürüşü Bitir"
                                  : "${_isGroupRide ? 'Grup ' : ''}Sürüşü Başlat"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
