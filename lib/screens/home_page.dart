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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TabController _tabController;
  late Future<ApiResponse<List<GroupEventResponse>>> _futureAllEvents;
  late Future<ApiResponse<List<GroupEventResponse>>> _futureMyEvents;

  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      setState(() {
        _futureAllEvents = Future.error("Kullanıcı doğrulaması başarısız.");
        _futureMyEvents = Future.error("Kullanıcı doğrulaması başarısız.");
        _dataLoaded = true;
      });
      return;
    }

    try {
      final allEventsResponse = await _eventService.getAllGroupEvents(token);
      final myEventsResponse = await _eventService.getMyGroupEvents(token);

      final myEventIds = myEventsResponse.data
          .map((e) => e.groupEventId)
          .toSet();

      final filteredAllEvents = allEventsResponse.data
          .where((e) => !myEventIds.contains(e.groupEventId))
          .toList();

      setState(() {
        _futureAllEvents = Future.value(
          ApiResponse(
            data: filteredAllEvents,
            message: "Tüm etkinlikler yüklendi",
          ),
        );
        _futureMyEvents = Future.value(
          ApiResponse(
            data: myEventsResponse.data,
            message: "Benim etkinliklerim yüklendi",
          ),
        );
        _dataLoaded = true;
      });
    } catch (e) {
      setState(() {
        _futureAllEvents = Future.error("Hata oluştu: $e");
        _futureMyEvents = Future.error("Hata oluştu: $e");
        _dataLoaded = true;
      });
    }
  }

  Widget _buildEventList(Future<ApiResponse<List<GroupEventResponse>>> future) {
    return FutureBuilder<ApiResponse<List<GroupEventResponse>>>(
      future: future,
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
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            return EventCard(event: events[index]);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: "Çift Teker",
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tüm Etkinlikler"),
            Tab(text: "Benim Etkinliklerim"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventList(_futureAllEvents),
          _buildEventList(_futureMyEvents),
        ],
      ),
    );
  }
}
