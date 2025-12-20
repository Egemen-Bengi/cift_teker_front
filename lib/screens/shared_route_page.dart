import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/like_response.dart';
import 'package:cift_teker_front/models/responses/record_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/like_service.dart';
import 'package:cift_teker_front/services/record_service.dart';
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
  final LikeService _likeService = LikeService();
  final RecordService _recordService = RecordService();

  late TabController _tabController;

  Future<ApiResponse<List<SharedRouteResponse>>>? _futureAllSharedRoutes;
  Future<ApiResponse<List<SharedRouteResponse>>>? _futureMySharedRoutes;

  Map<int, LikeResponse> _myLikes = {};
  Map<int, RecordResponse> _myRecords = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    final allRoutes = await _sharedRouteService.getAllSharedRoutes(token);
    final myRoutes = await _sharedRouteService.getSharedRoutes(token);

    final likes = await _likeService.getMyLikes(token);
    final records = await _recordService.getMyRecords(token);

    _myLikes = {for (var like in likes.data) like.sharedRouteId: like};
    _myRecords = {
      for (var record in records.data) record.sharedRouteId: record,
    };

    final myIds = myRoutes.data.map((e) => e.sharedRouteId).toSet();

    _futureAllSharedRoutes = Future.value(
      ApiResponse(
        data: allRoutes.data
            .where((e) => !myIds.contains(e.sharedRouteId))
            .toList(),
        message: "Tüm paylaşımlar",
      ),
    );

    _futureMySharedRoutes = Future.value(
      ApiResponse(data: myRoutes.data, message: "Benim paylaşımlarım"),
    );

    setState(() {});
  }

  Widget _buildRouteList(
    Future<ApiResponse<List<SharedRouteResponse>>> future,
  ) {
    return FutureBuilder<ApiResponse<List<SharedRouteResponse>>>(
      future: future,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final routes = snapshot.data!.data
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          itemCount: routes.length,
          itemBuilder: (_, index) {
            final route = routes[index];
            return SharedRouteCard(
              sharedRoute: route,
              myLike: _myLikes[route.sharedRouteId],
              myRecord: _myRecords[route.sharedRouteId],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_futureAllSharedRoutes == null || _futureMySharedRoutes == null) {
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
          _buildRouteList(_futureAllSharedRoutes!),
          _buildRouteList(_futureMySharedRoutes!),
        ],
      ),
    );
  }
}
