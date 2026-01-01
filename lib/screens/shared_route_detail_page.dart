import 'package:cift_teker_front/enum/DetailEntrySource.dart';
import 'package:cift_teker_front/models/responses/like_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/like_service.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:cift_teker_front/widgets/SharedRouteCard_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SharedRouteDetailPage extends StatefulWidget {
  final int sharedRouteId;
  final DetailEntrySource entrySource;

  const SharedRouteDetailPage({
    super.key,
    required this.sharedRouteId,
    this.entrySource = DetailEntrySource.normal,
  });

  @override
  State<SharedRouteDetailPage> createState() => _SharedRouteDetailPageState();
}

class _SharedRouteDetailPageState extends State<SharedRouteDetailPage> {
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LikeService _likeService = LikeService();

  LikeResponse? _currentLike;
  late Future<SharedRouteResponse> _futureRoute;

  bool _hasChanged = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _futureRoute = _loadRoute();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: "auth_token");
  }

  Future<void> _loadCurrentUser(SharedRouteResponse route) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _isOwner = false;
        return;
      }

      final decoded = JwtDecoder.decode(token);
      final int currentUserId = decoded["userId"];

      _isOwner = currentUserId == route.userId;
    } catch (_) {
      _isOwner = false;
    }
  }

  Future<SharedRouteResponse> _loadRoute() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) throw Exception("Token yok");

    final route = await _sharedRouteService.getSharedRouteById(
      widget.sharedRouteId,
      token,
    );
    await _loadCurrentUser(route);

    final likeApiResponse = await _likeService.getMyLikes(token);
    try {
      _currentLike = likeApiResponse.data.firstWhere(
        (l) => l.sharedRouteId == widget.sharedRouteId,
      );
    } catch (_) {
      _currentLike = null;
    }

    return route;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Rota",
        showBackButton: true,
        onBackButtonPressed: () => Navigator.pop(context, _hasChanged),
        showAvatar: false,
      ),
      body: FutureBuilder<SharedRouteResponse>(
        future: _futureRoute,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              SharedRouteCard(
                sharedRoute: snapshot.data!,
                myLike: _currentLike,
                isDetail: true,
                isOwner: _isOwner,
                onChanged: () {
                  _hasChanged = true;
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
