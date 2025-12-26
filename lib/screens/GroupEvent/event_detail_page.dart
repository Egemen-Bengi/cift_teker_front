import 'package:cift_teker_front/screens/GroupEvent/participant_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/responses/groupEvent_response.dart';
import '../../services/groupEventParticipant_service.dart';

class EventDetailPage extends StatefulWidget {
  final GroupEventResponse event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final GroupEventParticipantService _participantService =
      GroupEventParticipantService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  late bool _isJoined;

  @override
  void initState() {
    super.initState();
    _isJoined = widget.event.isJoined;
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: "auth_token");
  }

  Future<void> _joinEvent() async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      await _participantService.joinEvent(widget.event.groupEventId, token);

      setState(() {
        _isJoined = true;
      });
      if(!mounted) return;
      showAlertDialog(context, "Başarılı", "Etkinliğe katıldınız");
    } catch (e) {
      if(!mounted) return;
      showAlertDialog(
        context,
        "Hata",
        "Etkinliğe katılırken bir hata oluştu.",
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _leaveEvent() async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      await _participantService.leaveEvent(widget.event.groupEventId, token);

      setState(() {
        _isJoined = false;
      });
      if(!mounted) return;
      showAlertDialog(context, "Başarılı", "Etkinlikten ayrıldınız.");
    } catch (e) {
      if(!mounted) return;
      showAlertDialog(
        context,
        "Hata",
        "Etkinlikten ayrılırken bir hata oluştu.",
      );
    }

    setState(() => _isLoading = false);
  }

  void _openParticipants() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ParticipantPage(groupEventId: widget.event.groupEventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  _buildActionButton(
                    text: "Etkinliğe Katıl",
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    isEnabled: !_isJoined,
                    onTap: _joinEvent,
                  ),
                  const SizedBox(height: 16),

                  _buildActionButton(
                    text: "Etkinlikten Ayrıl",
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    isEnabled: _isJoined,
                    onTap: _leaveEvent,
                  ),
                  const SizedBox(height: 16),

                  _buildActionButton(
                    text: "Katılımcıları Gör",
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    isEnabled: true,
                    onTap: _openParticipants,
                  ),
                ],
              ),
            ),
    );
  }

  void showAlertDialog(BuildContext context, String title, String message) {
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
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
