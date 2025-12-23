import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/like_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/screens/shared_route_detail_page.dart';
import 'package:cift_teker_front/services/like_service.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:cift_teker_front/widgets/LikedRouteGridItem_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LikePage extends StatefulWidget {
  const LikePage({super.key});

  @override
  State<LikePage> createState() => _LikePageState();
}

class _LikePageState extends State<LikePage> {
  final LikeService _likeService = LikeService();
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<List<SharedRouteResponse>> _futureLikedRoutes;

  @override
  void initState() {
    super.initState();
    _futureLikedRoutes = _loadLikedRoutes();
  }

  Future<List<SharedRouteResponse>> _loadLikedRoutes() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      throw Exception("Token bulunamadı");
    }

    final ApiResponse<List<LikeResponse>> likeResponse = await _likeService
        .getMyLikes(token);

    final likes = likeResponse.data;

    final routes = await Future.wait(
      likes.map(
        (like) =>
            _sharedRouteService.getSharedRouteById(like.sharedRouteId, token),
      ),
    );

    return routes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Beğenilerim",
        showBackButton: true,
        onBackButtonPressed: () => Navigator.pop(context),
        showAvatar: false,
      ),
      body: FutureBuilder<List<SharedRouteResponse>>(
        future: _futureLikedRoutes,
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
                "Henüz beğendiğin bir rota yok 🚴‍♂️",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];

              return LikedRouteGridItem(
                route: route,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SharedRouteDetailPage(
                        sharedRouteId: route.sharedRouteId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
