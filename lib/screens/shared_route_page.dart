import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:cift_teker_front/widgets/SharedRouteCard_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SharedRoutePage extends StatefulWidget {
  const SharedRoutePage({super.key});

  @override
  State<SharedRoutePage> createState() => _SharedRoutePageState();
}

class _SharedRoutePageState extends State<SharedRoutePage> {
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<ApiResponse<List<SharedRouteResponse>>> _futureSharedRoutes;

  @override
  void initState() {
    super.initState();
    _futureSharedRoutes = _loadEvents();
  }

  Future<ApiResponse<List<SharedRouteResponse>>> _loadEvents() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      return Future.error("Kullanıcı doğrulaması başarısız.");
    }

    return _sharedRouteService.getAllSharedRoutes(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Paylaşılan Rotalar"),
      body: FutureBuilder<ApiResponse<List<SharedRouteResponse>>>(
        future: _futureSharedRoutes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata oluştu: ${snapshot.error}"));
          }

          if (snapshot.data == null || snapshot.data!.data.isEmpty) {
            return const Center(child: Text("Hiç paylaşım bulunamadı"));
          }

          final sharedRoutes = snapshot.data!.data;

          return ListView.builder(
            itemCount: sharedRoutes.length,
            itemBuilder: (context, index) {
              return SharedRouteCard(sharedRoute: sharedRoutes[index]);
            },
          );
        },
      ),
    );
  }
}
