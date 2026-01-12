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
import 'package:jwt_decoder/jwt_decoder.dart';

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

  List<SharedRouteResponse> _allRoutes = [];
  List<SharedRouteResponse> _myRoutes = [];

  Map<int, LikeResponse> _myLikes = {};
  Map<int, RecordResponse> _myRecords = {};

  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;

      final decoded = JwtDecoder.decode(token);
      _currentUserId = decoded["userId"];

      final results = await Future.wait([
        _sharedRouteService.getAllSharedRoutes(token),
        _sharedRouteService.getSharedRoutes(token),
        _likeService.getMyLikes(token),
        _recordService.getMyRecords(token),
      ]);

      if (!mounted) return;

      final allRoutesResp =
          results[0] as ApiResponse<List<SharedRouteResponse>>;
      final myRoutesResp = results[1] as ApiResponse<List<SharedRouteResponse>>;
      final likesResp = results[2] as ApiResponse<List<LikeResponse>>;
      final recordsResp = results[3] as ApiResponse<List<RecordResponse>>;

      final myIds = myRoutesResp.data.map((e) => e.sharedRouteId).toSet();

      setState(() {
        _myLikes = {for (var like in likesResp.data) like.sharedRouteId: like};
        _myRecords = {
          for (var record in recordsResp.data) record.sharedRouteId: record,
        };

        _myRoutes = myRoutesResp.data
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _allRoutes =
            allRoutesResp.data
                .where((e) => !myIds.contains(e.sharedRouteId))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRouteList(
    List<SharedRouteResponse> routes,
    String emptyMessage,
  ) {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: routes.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 60,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyMessage,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: routes.length,
              itemBuilder: (_, index) {
                final route = routes[index];
                final bool isOwner =
                    _currentUserId != null && route.userId == _currentUserId;

                return SharedRouteCard(
                  sharedRoute: route,
                  myLike: _myLikes[route.sharedRouteId],
                  myRecord: _myRecords[route.sharedRouteId],
                  isOwner: isOwner,
                  onChanged: () {
                    _loadEvents();
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
        title: "Paylaşılan Rotalar",
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tüm Paylaşılanlar"),
            Tab(text: "Benim Paylaştıklarım"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRouteList(_allRoutes, "Henüz hiç rota paylaşılmamış."),
                _buildRouteList(_myRoutes, "Henüz rota paylaşmadın."),
              ],
            ),
    );
  }
}
