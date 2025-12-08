import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/groupEvent_service.dart';
import '../core/models/api_response.dart';
import '../models/responses/groupEvent_response.dart';
import '../widgets/EventCard_Widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EventService _eventService = EventService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<ApiResponse<List<GroupEventResponse>>> _futureEvents;

  @override
  void initState() {
    super.initState();
    _futureEvents = _loadEvents();
  }

  Future<ApiResponse<List<GroupEventResponse>>> _loadEvents() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      return Future.error("Kullanıcı doğrulaması başarısız.");
    }

    return _eventService.getAllGroupEvents(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Çift Teker"),
      body: FutureBuilder<ApiResponse<List<GroupEventResponse>>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata oluştu: ${snapshot.error}"));
          }

          if (snapshot.data == null || snapshot.data!.data.isEmpty) {
            return const Center(child: Text("Hiç etkinlik bulunamadı"));
          }

          final now = DateTime.now();
          final events = List<GroupEventResponse>.from(snapshot.data!.data)
            ..removeWhere((event) => event.startDateTime.isBefore(now))
            ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime) * -1);

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return EventCard(event: events[index]);
            },
          );
        },
      ),
    );
  }
}
