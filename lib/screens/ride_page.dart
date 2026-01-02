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
import '../models/responses/groupEvent_response.dart';

class RidePage extends StatefulWidget {
  final GroupEventResponse? groupEvent;
  const RidePage({super.key, this.groupEvent});

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
  bool _isOwner = false;
  bool _isRideStarted = false;
  bool _isPageReady = false;
  bool _isConnecting = false;
  String? _token;

  int _elapsedSeconds = 0;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;

  BitmapDescriptor? _participantIcon;

  @override
  void initState() {
    super.initState();
    _isGroupRide = widget.groupEvent != null;
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _getToken();
    await _getUserLocation();
    await _loadUserId();
    await _loadMarkerIcons();

    if (!mounted) return;
    setState(() {
      if (_isGroupRide && widget.groupEvent != null && _userId != null) {
        _isOwner = _userId == widget.groupEvent!.userId;
      }
      _isPageReady = true;
    });
  }

  Future<void> _loadMarkerIcons() async {
    _participantIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/grupSurus.png',
    );
  }

  Future<void> _loadUserId() async {
    if (_token == null) return;
    try {
      final parts = _token!.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      _userId = payload["userId"];
    } catch (e) {
      debugPrint("Error decoding token: $e");
      _userId = null;
    }
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
      _updateCurrentUserMarker();
    } catch (e) {
      debugPrint('getUserLocation error: $e');
      // fallback: son bilinen konumu dene
      try {
        final Position? last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          setState(() {
            _currentPosition = LatLng(last.latitude, last.longitude);
          });
          _updateCurrentUserMarker();
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
        groupEventId: widget.groupEvent?.groupEventId,
      );

      if (rideId == null) {
        if (mounted) _show("Sürüş başlatılamadı");
        setState(() => _isConnecting = false);
        return;
      }

      _isGroupRide = widget.groupEvent != null;

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

  void _joinRide() {
    if (widget.groupEvent?.activeRideId == null) {
      _show("Sürüş ID'si bulunamadı. Katılım başarısız.");
      return;
    }

    if (_token == null || _token!.isEmpty) {
      _show("Token bulunamadı. Lütfen tekrar giriş yapın.");
      return;
    }

    setState(() {
      _rideId = widget.groupEvent!.activeRideId;
      _isRideStarted = true;
      _isConnecting = true; // To show loading while connecting to websocket
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
      _show("Grup sürüşüne katıldınız!");
    }
  }

  void _onStompConnect(StompFrame frame) {
    debugPrint("STOMP Bağlantısı Başarılı");

    if (!mounted) return;

    if (_isGroupRide && widget.groupEvent != null) {
      _stompClient!.subscribe(
        destination: '/topic/group/${widget.groupEvent!.groupEventId}',
        callback: (frame) {
          _handleLocationMessage(frame.body ?? "");
        },
      );
      debugPrint(
        "Subscribed to: /topic/group/${widget.groupEvent!.groupEventId}",
      );
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

      // Kendi konumumuzu bu event'ten almayalım.
      if (location.userId == _userId) return;

      setState(() {
        _participantLocations[location.userId] = location;
        _updateParticipantMarker(location);
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
        _ridePoints.add(currentPos);
        _totalDistance = _calculateDistanceKm(_ridePoints);
        _currentSpeed = pos.speed * 3.6;
        _elapsedSeconds += 5;
      });
      _updateCurrentUserMarker();

      if (_mapController != null && mounted) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(currentPos));
      }

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

      if (_ridePoints.isEmpty) {
        _show("Sürüş verisi bulunamadı");
        return;
      }

      // --- Ortak Mantık ---
      final List<LatLng> filteredPoints = <LatLng>[];
      for (int i = 0; i < _ridePoints.length; i += 10) {
        filteredPoints.add(_ridePoints[i]);
      }
      if (_ridePoints.isNotEmpty &&
          (filteredPoints.isEmpty || _ridePoints.last != filteredPoints.last)) {
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
      final DateTime rideEndDate = DateTime.now();

      // --- İstek Oluşturma ---
      final RideHistoryRequest request = RideHistoryRequest(
        mapData: mapData,
        distanceKm: _totalDistance,
        durationSeconds: _elapsedSeconds,
        averageSpeedKmh: averageSpeed,
        startDateTime: rideEndDate.subtract(Duration(seconds: _elapsedSeconds)),
        endDateTime: rideEndDate,
        groupEventId: _isGroupRide ? widget.groupEvent?.groupEventId : null,
      );

      // --- Kaydetme ---
      await _rideService.saveRideHistory(request, _token!);

      // --- Arayüz Güncelleme ---
      if (!mounted) return;
      setState(() {
        if (_isGroupRide) {
          _participantLocations.clear();
          _markers.removeWhere(
            (m) => m.markerId.value.startsWith('participant_'),
          );
        }
        _ridePoints.clear();
        _rideId = null;
        _isRideStarted = false;
        _elapsedSeconds = 0;
        _totalDistance = 0.0;
        _currentSpeed = 0.0;
      });

      if (mounted) {
        _show(
          _isGroupRide
              ? "Grup sürüşü tamamlandı"
              : "Sürüş kaydedildi - Mesafe: ${_totalDistance.toStringAsFixed(2)} km",
        );
      }
    } catch (e) {
      debugPrint("Sürüş durdurma hatası: $e");
      if (mounted) _show("Hata: $e");
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
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

  double _calculateAverageSpeed(double km, int seconds) {
    if (seconds == 0) return 0.0;
    return km / (seconds / 3600);
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minutesString = minutes.toString().padLeft(2, '0');
    final secondsString = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hoursString = hours.toString().padLeft(2, '0');
      return '$hoursString:$minutesString:$secondsString';
    } else {
      return '$minutesString:$secondsString';
    }
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _updateParticipantMarker(ParticipantLocation location) {
    final markerId = MarkerId('participant_${location.userId}');
    final marker = Marker(
      markerId: markerId,
      position: location.location,
      infoWindow: InfoWindow(
        title: location.username,
        snippet: 'Hız: ${location.speed.toStringAsFixed(1)} km/h',
      ),
      icon:
          _participantIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(marker);
    });
  }

  void _updateCurrentUserMarker() {
    if (_currentPosition == null) return;
    final markerId = const MarkerId('current_user');
    final marker = Marker(
      markerId: markerId,
      position: _currentPosition!,
      infoWindow: const InfoWindow(title: 'Benim Konumum'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(marker);
    });
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

  Widget _buildMainActionButton() {
    final String? eventStatus = widget.groupEvent?.status?.toUpperCase();

    final bool isEventInProgress = eventStatus == 'IN_PROGRESS';
    // Assume pending if status is null or PENDING
    final bool isEventPending = eventStatus == null || eventStatus == 'PENDING';
    final bool isEventCompleted = eventStatus == 'COMPLETED';

    String buttonText = "Yükleniyor...";
    Color buttonColor = Colors.grey;
    VoidCallback? onPressed;

    if (!_isPageReady || _isConnecting) {
      onPressed = null;
      buttonText = _isConnecting ? "Bağlanıyor..." : "Yükleniyor...";
    } else if (_isGroupRide) {
      // --- GROUP RIDE LOGIC ---
      if (_isOwner) {
        if (isEventInProgress) {
          buttonText = "Sürüşü Bitir";
          buttonColor = Colors.red;
          onPressed = _stopRide;
        } else if (isEventPending) {
          buttonText = "Grup Sürüşünü Başlat";
          buttonColor = Colors.green;
          onPressed = _startRide;
        } else {
          // Completed
          buttonText = "Sürüş Tamamlandı";
          onPressed = null;
        }
      } else {
        // Participant
        if (isEventPending) {
          buttonText = "Sürüşün Başlaması Bekleniyor";
          onPressed = null;
        } else if (isEventInProgress) {
          if (_isRideStarted) {
            buttonText = "Sürüşü Bitir";
            buttonColor = Colors.red;
            onPressed = _stopRide;
          } else {
            buttonText = "Sürüşe Katıl";
            buttonColor = Colors.green;
            onPressed = _joinRide;
          }
        } else if (isEventCompleted) {
          buttonText = "Sürüş Tamamlandı";
          onPressed = null;
        }
      }
    } else {
      // --- INDIVIDUAL RIDE LOGIC ---
      if (_isRideStarted) {
        buttonText = "Sürüşü Bitir";
        buttonColor = Colors.red;
        onPressed = _stopRide;
      } else {
        buttonText = "Sürüşü Başlat";
        buttonColor = Colors.green;
        onPressed = _startRide;
      }
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
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
                    child: _buildMainActionButton(),
                  ),
                ),
              ],
            ),
    );
  }
}
