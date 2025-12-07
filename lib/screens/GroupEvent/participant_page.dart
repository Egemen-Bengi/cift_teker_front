import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/groupEventParticipant_service.dart';
import '../../models/responses/groupEventParticipant_response.dart';

class ParticipantPage extends StatefulWidget {
  final int groupEventId;

  const ParticipantPage({super.key, required this.groupEventId});

  @override
  State<ParticipantPage> createState() => _ParticipantPageState();
}

class _ParticipantPageState extends State<ParticipantPage> {
  final GroupEventParticipantService _participantService =
      GroupEventParticipantService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // late yerine nullable Future kullan ve null check'i build içinde yap
  Future<List<GroupEventParticipantResponse>>? _futureParticipants;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final token = await _storage.read(key: "auth_token");

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      // Token yoksa error Future set et
      setState(() {
        _futureParticipants =
            Future<List<GroupEventParticipantResponse>>.error(
                "Oturum bulunamadı. Lütfen giriş yapın.");
      });
      return;
    }

    // Token varsa API çağrısını başlat
    setState(() {
      _futureParticipants =
          _participantService.getParticipants(widget.groupEventId, token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Katılımcılar"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        // _futureParticipants null ise loading göster
        child: _futureParticipants == null
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<GroupEventParticipantResponse>>(
                future: _futureParticipants,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Hata: ${snapshot.error}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final participants = snapshot.data ?? [];

                  if (participants.isEmpty) {
                    return const Center(
                      child: Text(
                        "Hiç katılımcı yok",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      return _buildParticipantCard(p);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildParticipantCard(GroupEventParticipantResponse p) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            // username ve katılım zamanı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.username,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Katıldı: ${p.joinedAt}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Katılım durumu
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                p.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
