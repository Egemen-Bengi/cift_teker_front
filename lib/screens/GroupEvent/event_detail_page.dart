import 'package:cift_teker_front/screens/GroupEvent/participant_page.dart';
import 'package:cift_teker_front/screens/GroupEvent/editEvent_page.dart';
import 'package:cift_teker_front/screens/ride_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../models/responses/groupEvent_response.dart';
import '../../services/groupEventParticipant_service.dart';
import '../../services/groupEvent_service.dart';

class EventDetailPage extends StatefulWidget {
  final GroupEventResponse event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _participantService = GroupEventParticipantService();
  final _eventService = EventService();
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isJoined = false;
  bool _isOwner = false;
  bool _userLoaded = false;

  late GroupEventResponse _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _isJoined = _currentEvent.isJoined;
    _loadCurrentUser();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: "auth_token");
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = await _getToken();

      if (token == null) {
        _finishUserLoad(false);
        return;
      }

      final decoded = JwtDecoder.decode(token);
      final int currentUserId = decoded["userId"];

      setState(() {
        _isOwner = currentUserId == _currentEvent.userId;
        if (_isOwner) {
          _isJoined = false;
        }
        _userLoaded = true;
      });
    } catch (e) {
      _finishUserLoad(false);
    }
  }

  void _finishUserLoad(bool isOwner) {
    setState(() {
      _isOwner = isOwner;
      _userLoaded = true;
    });
  }

  /// ➕ Etkinliğe katıl
  Future<void> _joinEvent() async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      await _participantService.joinEvent(_currentEvent.groupEventId, token);
      setState(() => _isJoined = true);

      _showAlertDialog("Başarılı", "Etkinliğe katıldınız.");
    } catch (_) {
      _showAlertDialog("Hata", "Etkinliğe katılırken bir hata oluştu.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _leaveEvent() async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      await _participantService.leaveEvent(_currentEvent.groupEventId, token);
      setState(() => _isJoined = false);

      _showAlertDialog("Başarılı", "Etkinlikten ayrıldınız.");
    } catch (_) {
      _showAlertDialog("Hata", "Etkinlikten ayrılırken bir hata oluştu.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteEvent() async {
    final token = await _getToken();
    if (token == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Etkinliği Sil"),
        content: const Text("Bu etkinliği silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _eventService.deleteGroupEvent(_currentEvent.groupEventId, token);
      if (mounted) Navigator.pop(context, _currentEvent);
      return;
    } catch (e) {
      print(e);
      _showAlertDialog("Hata", "Etkinlik silinirken bir hata oluştu.");
    }

    setState(() => _isLoading = false);
  }

  void _openParticipants() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ParticipantPage(groupEventId: _currentEvent.groupEventId),
      ),
    );
  }

  void _navigateToGroupRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RidePage(groupEventId: _currentEvent.groupEventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_userLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        if (mounted) Navigator.pop(context, _currentEvent);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentEvent.title),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, _currentEvent),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildActionButton(
                      text: "Etkinliğe Katıl",
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      isEnabled: !_isOwner && !_isJoined,
                      onTap: _joinEvent,
                    ),
                    const SizedBox(height: 16),

                    _buildActionButton(
                      text: "Etkinlikten Ayrıl",
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                      isEnabled: !_isOwner && _isJoined,
                      onTap: _leaveEvent,
                    ),
                    const SizedBox(height: 16),

                    _buildActionButton(
                      text: "Grup Sürüşüne Katıl",
                      icon: Icons.directions_bike,
                      color: Colors.purple,
                      isEnabled: _isJoined || _isOwner,
                      onTap: _navigateToGroupRide,
                    ),
                    const SizedBox(height: 16),

                    _buildActionButton(
                      text: "Katılımcıları Gör",
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      isEnabled: true,
                      onTap: _openParticipants,
                    ),

                    if (_isOwner) ...[
                      const SizedBox(height: 16),
                      _buildActionButton(
                        text: "Etkinliği Düzenle",
                        icon: Icons.edit_outlined,
                        color: Colors.indigo,
                        isEnabled: true,
                        onTap: () async {
                          final result =
                              await Navigator.push<GroupEventResponse?>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditEventPage(event: _currentEvent),
                                ),
                              );

                          if (result != null) {
                            setState(() {
                              _currentEvent = result;
                              _isJoined = _currentEvent.isJoined;
                            });
                            _showAlertDialog(
                              "Başarılı",
                              "Etkinlik güncellendi.",
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        text: "Etkinliği Sil",
                        icon: Icons.delete_outline,
                        color: Colors.orange,
                        isEnabled: true,
                        onTap: _deleteEvent,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final effectiveColor = isEnabled ? color : Colors.grey.shade400;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: effectiveColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
