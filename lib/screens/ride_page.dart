import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/ParticipantLocation.dart';
import '../models/responses/groupEvent_response.dart';
import '../services/rideHistory_service.dart';
import '../services/groupEvent_service.dart';
import '../widgets/CustomAppBar_Widget.dart';
import '../models/requests/rideHistory_request.dart';

class RidePage extends StatefulWidget {
  final int? groupEventId;
  final int? creatorId;

  const RidePage({super.key, this.groupEventId, this.creatorId});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final RideHistoryService _rideHistoryService = RideHistoryService();
  final EventService _eventService = EventService();

  final String _socketUrl =
      'https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/ws';

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final List<LatLng> _ridePoints = [];

  final Map<int, ParticipantLocation> _participantLocations = {};
  final Set<Marker> _markers = {};

  StompClient? _stompClient;
  Timer? _locationTimer;
  Timer? _statusPollingTimer;

  int? _rideId;
  int? _userId;
  int? _eventCreatorId;
  String? _token;

  bool _isGroupRide = false;
  bool _isRideStarted = false;
  bool _isPageReady = false;
  bool _isConnecting = false;
  bool _isOwner = false;

  String _eventStatus = "PLANNED";
  int _apiParticipantCount = 0;

  int _elapsedSeconds = 0;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _isGroupRide = widget.groupEventId != null;
    if (widget.creatorId != null) {
      _eventCreatorId = widget.creatorId;
    }
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _getToken();
    await _getUserLocation();
    await _decodeUserToken();

    if (_isGroupRide) {
      await _fetchEventStatus();
    } else {
      _isOwner = true;
      _eventStatus = "IN_PROGRESS";
    }

    if (!mounted) return;
    setState(() {
      _isPageReady = true;
    });

    if (_isGroupRide && !_isOwner && _eventStatus == "PLANNED") {
      _startStatusPolling();
    }
  }

  Future<void> _getToken() async {
    _token = await _storage.read(key: "auth_token");
    if ((_token == null || _token!.isEmpty) && mounted) {
      _showSnack("Token bulunamadı. Lütfen tekrar giriş yapın.");
    }
  }

  Future<void> _decodeUserToken() async {
    if (_token == null || _token!.isEmpty) return;
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      _userId = decodedToken["userId"] ?? decodedToken["id"];

      if (_eventCreatorId != null && _userId != null) {
        _isOwner = (_userId == _eventCreatorId);
      } else if (!_isGroupRide) {
        _isOwner = true;
      }
    } catch (e) {
      debugPrint("Token decode hatası: $e");
    }
  }

  Future<void> _fetchEventStatus() async {
    if (widget.groupEventId == null || _token == null) return;

    try {
      final response = await _eventService.getAllGroupEvents(_token!);

      if (response.data.isNotEmpty) {
        try {
          final GroupEventResponse targetEvent = response.data.firstWhere(
            (event) => event.groupEventId == widget.groupEventId,
          );

          if (mounted) {
            setState(() {
              _eventStatus = targetEvent.status ?? "PLANNED";
              _eventCreatorId = targetEvent.userId;
              _apiParticipantCount = targetEvent.currentParticipants ?? 0;

              if (_userId != null) {
                _isOwner = (_userId == targetEvent.userId);
              }
            });
          }
        } catch (e) {
          debugPrint("Etkinlik listede bulunamadı: $e");
        }
      }
    } catch (e) {
      debugPrint("Etkinlik listesi çekilemedi: $e");
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      await _fetchEventStatus();
      if (_eventStatus == "IN_PROGRESS") {
        timer.cancel();
        if (mounted) {
          _showSnack("Etkinlik sahibi sürüşü başlattı! Katılabilirsiniz.");
        }
      }
    });
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      debugPrint("Konum hatası: $e");
    }
  }

  Future<void> _startRide() async {
    if (_isGroupRide && !_isOwner && _eventStatus != "IN_PROGRESS") {
      _showSnack("Etkinlik sahibi henüz sürüşü başlatmadı.");
      return;
    }

    if (_currentPosition == null) await _getUserLocation();

    setState(() => _isConnecting = true);

    try {
      final int? rideId = await _rideHistoryService.startRide(
        _token!,
        groupEventId: widget.groupEventId,
      );

      if (rideId == null) {
        if (mounted) _showSnack("Sürüş başlatılamadı.");
        setState(() => _isConnecting = false);
        return;
      }

      setState(() {
        _rideId = rideId;
        _isRideStarted = true;
        if (_isOwner) _eventStatus = "IN_PROGRESS";
      });

      _initSocketConnection();

      if (mounted) {
        _showSnack(
          _isGroupRide ? "Grup sürüşüne katıldınız!" : "Sürüş başladı!",
        );
      }
    } catch (e) {
      _showSnack("Hata: $e");
      setState(() => _isConnecting = false);
    }
  }

  void _initSocketConnection() {
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _socketUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $_token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $_token'},
        onConnect: _onStompConnect,
        onWebSocketError: (err) => debugPrint("WebSocket Hata: $err"),
      ),
    );
    _stompClient!.activate();
  }

  void _onStompConnect(StompFrame frame) {
    if (!mounted) return;

    if (_isGroupRide && widget.groupEventId != null) {
      _stompClient!.subscribe(
        destination: '/topic/group/${widget.groupEventId}',
        callback: (frame) {
          _handleLocationMessage(frame.body ?? "");
        },
      );
    } else {
      debugPrint("Grup ID yok veya Bireysel Sürüş Modu! Grup dinlenmiyor.");
    }

    if (_rideId != null) {
      _stompClient!.subscribe(
        destination: '/topic/ride/$_rideId',
        callback: (frame) => _handleLocationMessage(frame.body ?? ""),
      );
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
        if (location.userId != _userId) {
          _participantLocations[location.userId] = location;
          _updateMarkers();
        } else {
          debugPrint(
            "Kendi verimi aldım, haritaya başkası olarak eklemiyorum.",
          );
        }
      });
    } catch (e) {
      debugPrint("JSON Parse Hatası: $e");
    }
  }

  void _updateMarkers() {
    _markers.clear();

    for (final entry in _participantLocations.entries) {
      final loc = entry.value;

      double markerHue = BitmapDescriptor.hueBlue;
      String roleTitle = loc.username;

      if (_eventCreatorId != null && loc.userId == _eventCreatorId) {
        markerHue = BitmapDescriptor.hueGreen;
        roleTitle = "${loc.username} (Kurucu)";
      }

      _markers.add(
        Marker(
          markerId: MarkerId('user_${loc.userId}'),
          position: loc.location,
          infoWindow: InfoWindow(
            title: roleTitle,
            snippet: '${loc.speed.toStringAsFixed(1)} km/h',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        ),
      );
    }

    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Ben'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _startLocationUpdates() {
    _sendCurrentLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _sendCurrentLocation();
    });
  }

  Future<void> _sendCurrentLocation() async {
    if (!mounted || _stompClient == null) return;

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentPos = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentPosition = currentPos;
        _ridePoints.add(currentPos);
        _totalDistance = _calculateDistanceKm(_ridePoints);
        _currentSpeed = pos.speed * 3.6;
        _elapsedSeconds += 5;
        _updateMarkers();
      });

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(currentPos));
      }

      final Map<String, dynamic> payloadMap = {
        "userId": _userId,
        "rideId": _rideId,
        "groupEventId": widget.groupEventId,
        "latitude": currentPos.latitude,
        "longitude": currentPos.longitude,
        "speed": _currentSpeed,
        "timestamp": DateTime.now().toUtc().toIso8601String(),
      };

      final String payload = jsonEncode(payloadMap);

      _stompClient!.send(destination: "/app/sendLocation", body: payload);
    } catch (e) {
      debugPrint("Konum gönderme hatası: $e");
    }
  }

  Future<void> _stopRide() async {
    _locationTimer?.cancel();
    _statusPollingTimer?.cancel();
    setState(() => _isConnecting = true);

    try {
      _stompClient?.deactivate();
      _stompClient = null;

      if (_ridePoints.isNotEmpty) {
        List<LatLng> filteredPoints = [];
        for (int i = 0; i < _ridePoints.length; i += 10) {
          filteredPoints.add(_ridePoints[i]);
        }
        if (filteredPoints.isEmpty || filteredPoints.last != _ridePoints.last) {
          filteredPoints.add(_ridePoints.last);
        }

        final String mapData = jsonEncode(
          filteredPoints
              .map((e) => {'latitude': e.latitude, 'longitude': e.longitude})
              .toList(),
        );
        final double avgSpeed = _elapsedSeconds > 0
            ? _totalDistance / (_elapsedSeconds / 3600)
            : 0.0;

        final req = RideHistoryRequest(
          mapData: mapData,
          distanceKm: _totalDistance,
          durationSeconds: _elapsedSeconds,
          averageSpeedKmh: avgSpeed,
          startDateTime: DateTime.now().subtract(
            Duration(seconds: _elapsedSeconds),
          ),
          endDateTime: DateTime.now(),
          groupEventId: widget.groupEventId,
        );

        await _rideHistoryService.saveRideHistory(req, _token!);
      }

      if (mounted) {
        _showSnack(
          "Sürüş kaydedildi. Mesafe: ${_totalDistance.toStringAsFixed(2)} km",
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack("Hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _statusPollingTimer?.cancel();
    _stompClient?.deactivate();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = "Yükleniyor...";
    bool isButtonEnabled = false;
    Color buttonColor = Colors.grey;

    if (_isPageReady) {
      if (_isRideStarted) {
        buttonText = _isGroupRide ? "Sürüşten Ayrıl" : "Sürüşü Bitir";
        buttonColor = Colors.red;
        isButtonEnabled = !_isConnecting;
      } else {
        if (_isOwner) {
          buttonText = "Grup Sürüşünü Başlat";
          buttonColor = Colors.green;
          isButtonEnabled = !_isConnecting;
        } else {
          if (_eventStatus == "IN_PROGRESS") {
            buttonText = "Sürüşe Katıl";
            buttonColor = Colors.blue;
            isButtonEnabled = !_isConnecting;
          } else {
            buttonText = "Etkinlik Sahibi Bekleniyor...";
            buttonColor = Colors.grey;
            isButtonEnabled = false;
          }
        }
      }
    }

    String participantCountText = _isRideStarted
        ? "Katılımcılar: ${_participantLocations.length + 1}"
        : "Katılımcılar: $_apiParticipantCount";

    return Scaffold(
      appBar: CustomAppBar(title: "Grup Sürüşü"),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => _mapController = c,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId("myRoute"),
                      points: _ridePoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
                  markers: _markers,
                ),

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
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(participantCountText),
                          Text("Hız: ${_currentSpeed.toStringAsFixed(1)} km/h"),
                        ],
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
                      onPressed: isButtonEnabled
                          ? (_isRideStarted ? _stopRide : _startRide)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              buttonText,
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
