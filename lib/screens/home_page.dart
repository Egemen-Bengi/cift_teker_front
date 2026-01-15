import 'package:cift_teker_front/cities/turkish_cities.dart';
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
  final List<String> _turkishCities = TurkishCities.list;

  late TabController _tabController;
  late Future<ApiResponse<List<GroupEventResponse>>> _futureAllEvents;
  late Future<ApiResponse<List<GroupEventResponse>>> _futureMyEvents;
  String? _token;

  bool _dataLoaded = false;

  String? _selectedCityAll;
  String? _selectedCityMy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final token = await _storage.read(key: "auth_token");
    _token = token;
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _futureAllEvents = Future.error("Kullanıcı doğrulaması başarısız.");
        _futureMyEvents = Future.error("Kullanıcı doğrulaması başarısız.");
        _dataLoaded = true;
      });
      return;
    }

    try {
      final allEventsResponse = await _eventService.getAllGroupEvents(token);
      if (!mounted) return;

      final myEventsResponse = await _eventService.getMyGroupEvents(token);
      if (!mounted) return;

      final myEventIds = myEventsResponse.data
          .map((e) => e.groupEventId)
          .toSet();

      final filteredAllEvents = allEventsResponse.data
          .where((e) => !myEventIds.contains(e.groupEventId))
          .toList();

      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _futureAllEvents = Future.error("Hata oluştu: $e");
        _futureMyEvents = Future.error("Hata oluştu: $e");
        _dataLoaded = true;
      });
    }
  }

  Widget _buildCityFilter({required bool isAllTab}) {
    final selectedCity = isAllTab ? _selectedCityAll : _selectedCityMy;
    void updateCity(String? value) {
      setState(() {
        if (isAllTab) {
          _selectedCityAll = value;
        } else {
          _selectedCityMy = value;
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCity,
                  hint: Text(
                    "Şehir Seçiniz (Tümü)",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  icon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.indigo,
                  ),
                  menuMaxHeight: 250,
                  items: _turkishCities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(
                        city,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: city == selectedCity
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: city == selectedCity
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: updateCity,
                ),
              ),
            ),
          ),
          if (selectedCity != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: () => updateCity(null),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.filter_alt_off,
                    color: Colors.indigo,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventList(
    Future<ApiResponse<List<GroupEventResponse>>> future, {
    required bool isAllTab,
  }) {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: Colors.purple.shade600,
      child: FutureBuilder<ApiResponse<List<GroupEventResponse>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(child: Text("Hata oluştu: ${snapshot.error}")),
              ],
            );
          }

          if (snapshot.data == null || snapshot.data!.data.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(child: Text("Hiç etkinlik bulunamadı")),
              ],
            );
          }

          final now = DateTime.now();
          final events = List<GroupEventResponse>.from(snapshot.data!.data)
            ..removeWhere((event) {
              final status = event.status?.toUpperCase();
              final isExpired = event.endDateTime.isBefore(now);

              if (status == 'COMPLETED') return true;
              if (status == 'PENDING' && isExpired) return true;
              return false;
            })
            ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

          final selectedCity = isAllTab ? _selectedCityAll : _selectedCityMy;
          if (selectedCity != null) {
            events.removeWhere(
              (event) =>
                  event.city?.toUpperCase().trim() != selectedCity.trim(),
            );
          }

          if (events.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(child: Text("Bu kriterlerde etkinlik yok")),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return EventCard(
                event: events[index],
                token: _token,
                onUpdated: () => _loadEvents(),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: !_dataLoaded
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    _buildCityFilter(isAllTab: true),
                    Expanded(
                      child: _buildEventList(_futureAllEvents, isAllTab: true),
                    ),
                  ],
                ),
                Column(
                  children: [
                    _buildCityFilter(isAllTab: false),
                    Expanded(
                      child: _buildEventList(_futureMyEvents, isAllTab: false),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
