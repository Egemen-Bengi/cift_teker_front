import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/record_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/record_service.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:cift_teker_front/widgets/SharedRouteCard_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final RecordService _recordService = RecordService();
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<List<SharedRouteResponse>> _futureRecordedRoutes;

  @override
  void initState() {
    super.initState();
    _futureRecordedRoutes = _loadRecordedRoutes();
  }

  Future<List<SharedRouteResponse>> _loadRecordedRoutes() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      throw Exception("Token bulunamadı");
    }

    final ApiResponse<List<RecordResponse>> response = await _recordService
        .getMyRecords(token);

    final records = response.data;

    final Set<int> routeIds = records.map((r) => r.sharedRouteId).toSet();

    final List<SharedRouteResponse> routes = [];

    for (final id in routeIds) {
      final route = await _sharedRouteService.getSharedRouteById(id, token);
      routes.add(route);
    }

    return routes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Kaydedilenler",
        showBackButton: true,
        onBackButtonPressed: () => Navigator.pop(context),
        showAvatar: false,
      ),
      body: FutureBuilder<List<SharedRouteResponse>>(
        future: _futureRecordedRoutes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final routes = snapshot.data ?? [];

          if (routes.isEmpty) {
            return const Center(
              child: Text(
                "Henüz kaydettiğin bir paylaşım yok 🔖",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              return SharedRouteCard(sharedRoute: routes[index]);
            },
          );
        },
      ),
    );
  }
}
