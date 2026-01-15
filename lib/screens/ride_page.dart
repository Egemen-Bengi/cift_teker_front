import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
  final Map<int, BitmapDescriptor> _markerIconCache = {};
  final Set<Marker> _markers = {};

  StompClient? _stompClient;
  Timer? _locationTimer;
  Timer? _statusPollingTimer;

  int? _rideId;
  int? _userId;
  int? _eventCreatorId;
  String? _token;
  String _myUsername = "Ben";

  bool _isGroupRide = false;
  bool _isRideStarted = false;
  bool _isPageReady = false;
  bool _isConnecting = false;
  bool _isOwner = false;
  bool _isSaving = false;

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

    _generateMyMarker();

    if (_isGroupRide && !_isOwner && _eventStatus == "PLANNED") {
      _startStatusPolling();
    }
  }

  Future<void> _generateMyMarker() async {
    if (_userId != null) {
      final icon = await _createCustomMarkerBitmap(_myUsername, isMe: true);
      if (mounted) {
        setState(() {
          _markerIconCache[_userId!] = icon;
          _updateMarkers();
        });
      }
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
      _myUsername = decodedToken["sub"] ?? "Ben";

      if (_eventCreatorId != null && _userId != null) {
        _isOwner = (_userId == _eventCreatorId);
      } else if (!_isGroupRide) {
        _isOwner = true;
      }

      if (mounted) {
        _generateMyMarker();
      }
    } catch (e) {
      debugPrint("Token decode hatası: $e");
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    String name, {
    bool isMe = false,
    bool isCreator = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();

    final Canvas canvas = Canvas(pictureRecorder);

    const double size = 120.0;
    const double shadowWidth = 4.0;
    const double borderSize = 6.0;

    final Paint shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
    final Paint borderPaint = Paint()..color = Colors.white;

    Color roleColor = Colors.blue;
    if (isMe)
      roleColor = Colors.red;
    else if (isCreator)
      roleColor = Colors.green;

    final Paint rolePaint = Paint()..color = roleColor;

    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 4),
      (size / 2) - shadowWidth,
      shadowPaint,
    );

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      (size / 2) - shadowWidth,
      rolePaint,
    );

    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      (size / 2) - shadowWidth - borderSize,
      borderPaint,
    );

    final Paint innerCirclePaint = Paint()..color = Colors.grey.shade200;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      (size / 2) - shadowWidth - borderSize - 2,
      innerCirclePaint,
    );

    String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: initial,
      style: TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.bold,
        color: roleColor,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final Path path = Path();
    path.moveTo(size / 2 - 10, size - 10);
    path.lineTo(size / 2, size + 10);
    path.lineTo(size / 2 + 10, size - 10);
    path.close();
    canvas.drawPath(path, rolePaint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      (size + 15).toInt(),
    );

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) return BitmapDescriptor.defaultMarker;

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
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

  void _handleLocationMessage(String messageBody) async {
    if (messageBody.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(messageBody);
      final ParticipantLocation location = ParticipantLocation.fromJson(data);

      if (!mounted) return;

      if (_isGroupRide &&
          !_isOwner &&
          location.userId == _eventCreatorId &&
          location.speed == -1.0) {
        _handleOwnerEndedRide();
        return;
      }

      if (!_markerIconCache.containsKey(location.userId) &&
          location.userId != _userId) {
        bool isCreator =
            _eventCreatorId != null && location.userId == _eventCreatorId;
        final icon = await _createCustomMarkerBitmap(
          location.username,
          isCreator: isCreator,
        );
        if (mounted) {
          setState(() {
            _markerIconCache[location.userId] = icon;
          });
        }
      }

      setState(() {
        if (location.userId != _userId) {
          _participantLocations[location.userId] = location;
          _updateMarkers();
        }
      });
    } catch (e) {
      debugPrint("JSON Parse Hatası: $e");
    }
  }

  void _handleOwnerEndedRide() {
    if (_isSaving) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Etkinlik Sona Erdi"),
        content: const Text("Kurucu sürüşü bitirdi. Sürüşünüz kaydediliyor..."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopRide(isOwnerTermination: true);
            },
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  void _updateMarkers() {
    _markers.clear();

    for (final entry in _participantLocations.entries) {
      final loc = entry.value;

      BitmapDescriptor icon =
          _markerIconCache[loc.userId] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);

      _markers.add(
        Marker(
          markerId: MarkerId('user_${loc.userId}'),
          position: loc.location,
          infoWindow: InfoWindow(
            title: loc.username,
            snippet: '${loc.speed.toStringAsFixed(1)} km/h',
          ),
          icon: icon,
        ),
      );
    }

    if (_currentPosition != null && _userId != null) {
      BitmapDescriptor myIcon =
          _markerIconCache[_userId!] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      _markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Ben'),
          icon: myIcon,
          zIndex: 2,
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
        "username": _myUsername,
      };

      final String payload = jsonEncode(payloadMap);
      _stompClient!.send(destination: "/app/sendLocation", body: payload);
    } catch (e) {
      debugPrint("Konum gönderme hatası: $e");
    }
  }

  Future<void> _stopRide({bool isOwnerTermination = false}) async {
    if (_isSaving) return;

    _locationTimer?.cancel();
    _statusPollingTimer?.cancel();

    if (mounted) {
      setState(() {
        _isConnecting = true;
        _isSaving = true;
      });
    }

    try {
      if (_isOwner &&
          _isGroupRide &&
          !isOwnerTermination &&
          _stompClient != null) {
        final signalPayload = jsonEncode({
          "userId": _userId,
          "rideId": _rideId,
          "groupEventId": widget.groupEventId,
          "latitude": _currentPosition?.latitude ?? 0.0,
          "longitude": _currentPosition?.longitude ?? 0.0,
          "speed": -1.0,
          "timestamp": DateTime.now().toUtc().toIso8601String(),
        });
        _stompClient!.send(
          destination: "/app/sendLocation",
          body: signalPayload,
        );

        await Future.delayed(const Duration(milliseconds: 500));
      }

      _stompClient?.deactivate();
      _stompClient = null;

      List<LatLng> filteredPoints = [];
      if (_ridePoints.isNotEmpty) {
        for (int i = 0; i < _ridePoints.length; i += 10) {
          filteredPoints.add(_ridePoints[i]);
        }
        if (filteredPoints.isEmpty || filteredPoints.last != _ridePoints.last) {
          filteredPoints.add(_ridePoints.last);
        }
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

      if (mounted) {
        if (!isOwnerTermination) {
          _showSnack("Sürüş kaydedildi.");
        }
        if (widget.groupEventId != null) {
          Navigator.pop(context);
        } else {
          setState(() {
            _isConnecting = false;
            _isSaving = false;
            _isRideStarted = false;

            _elapsedSeconds = 0;
            _totalDistance = 0.0;
            _currentSpeed = 0.0;

            _ridePoints.clear();
            _participantLocations.clear();
            _markers.clear();

            _rideId = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Sürüş kaydetme hatası: $e");
      if (mounted) _showSnack("Kaydederken hata oluştu: $e");
      setState(() {
        _isConnecting = false;
        _isSaving = false;
      });
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

  void _goBackToEventDetail() {
    Navigator.of(context).pop();
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
          buttonText = _isGroupRide
              ? "Grup Sürüşünü Başlat"
              : "Bireysel Sürüş Başlat";
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
      appBar: CustomAppBar(
        title: _isGroupRide ? "Grup Sürüşü" : "Bireysel Sürüş",
        onBackButtonPressed: _isGroupRide ? _goBackToEventDetail : null,
        showBackButton: _isGroupRide,
        showAvatar: !_isGroupRide,
      ),
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
                  myLocationEnabled: false,
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
                          ? (_isRideStarted ? () => _stopRide() : _startRide)
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
