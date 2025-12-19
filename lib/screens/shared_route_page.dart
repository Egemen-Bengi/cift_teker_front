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

class _SharedRoutePageState extends State<SharedRoutePage>
    with SingleTickerProviderStateMixin {
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late TabController _tabController;

  late Future<ApiResponse<List<SharedRouteResponse>>> _futureAllSharedRoutes;
  late Future<ApiResponse<List<SharedRouteResponse>>> _futureMySharedRoutes;

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
        _futureAllSharedRoutes = Future.error(
          "Kullanıcı doğrulaması başarısız.",
        );
        _futureMySharedRoutes = Future.error(
          "Kullanıcı doğrulaması başarısız.",
        );
        _dataLoaded = true;
      });
      return;
    }

    try {
      final allSharedRoutes = await _sharedRouteService.getAllSharedRoutes(
        token,
      );
      final mySharedRoutes = await _sharedRouteService.getSharedRoutes(token);

      /// Benim paylaştıklarımı tüm paylaşılanlardan çıkar
      final myRouteIds = mySharedRoutes.data
          .map((e) => e.sharedRouteId)
          .toSet();

      final filteredAllRoutes = allSharedRoutes.data
          .where((e) => !myRouteIds.contains(e.sharedRouteId))
          .toList();

      setState(() {
        _futureAllSharedRoutes = Future.value(
          ApiResponse(
            data: filteredAllRoutes,
            message: "Tüm paylaşılan rotalar",
          ),
        );

        _futureMySharedRoutes = Future.value(
          ApiResponse(
            data: mySharedRoutes.data,
            message: "Benim paylaştığım rotalar",
          ),
        );

        _dataLoaded = true;
      });
    } catch (e) {
      setState(() {
        _futureAllSharedRoutes = Future.error("Hata oluştu: $e");
        _futureMySharedRoutes = Future.error("Hata oluştu: $e");
        _dataLoaded = true;
      });
    }
  }

  Widget _buildRouteList(
    Future<ApiResponse<List<SharedRouteResponse>>> future,
  ) {
    return FutureBuilder<ApiResponse<List<SharedRouteResponse>>>(
      future: future,
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

        final routes = snapshot.data!.data
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            return SharedRouteCard(sharedRoute: routes[index]);
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
        title: "Paylaşılan Rotalar",
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tüm Paylaşılanlar"),
            Tab(text: "Benim Paylaştıklarım"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRouteList(_futureAllSharedRoutes),
          _buildRouteList(_futureMySharedRoutes),
        ],
      ),
    );
  }
}
