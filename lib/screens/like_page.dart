import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/like_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/like_service.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:cift_teker_front/widgets/SharedRouteCard_Widget.dart';
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

    final List<SharedRouteResponse> routes = [];

    for (final like in likes) {
      final route = await _sharedRouteService.getSharedRouteById(
        like.sharedRouteId,
        token,
      );
      routes.add(route);
    }

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
