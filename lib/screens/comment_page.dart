import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/comment_response.dart';
import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/comment_service.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:cift_teker_front/widgets/SharedRouteCard_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class CommentPage extends StatefulWidget {
  const CommentPage({super.key});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final CommentService _commentService = CommentService();
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<List<SharedRouteResponse>> _futureCommentedRoutes;
  List<SharedRouteResponse>? _cachedRoutes;
  bool _hasLoadedOnce = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _futureCommentedRoutes = _loadCommentedRoutes();
    _futureCommentedRoutes.then((routes) {
      if (mounted) setState(() {
        _cachedRoutes = routes;
        _hasLoadedOnce = true;
      });
    });
  }

  Future<void> _loadCurrentUser() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    try {
      final decoded = JwtDecoder.decode(token);
      setState(() {
        _currentUserId = decoded["userId"];
      });
    } catch (_) {}
  }

  Future<List<SharedRouteResponse>> _loadCommentedRoutes() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      throw Exception("Token bulunamadı");
    }

    final ApiResponse<List<CommentResponse>> response = await _commentService
        .getMyComments(token);

    final Set<int> routeIds = response.data
        .where((c) => c.sharedRouteId != null)
        .map((c) => c.sharedRouteId!)
        .toSet();

    final routes = await Future.wait(
      routeIds.map((id) => _sharedRouteService.getSharedRouteById(id, token)),
    );

    return routes;
  }

  Future<void> _refresh() async {
    final f = _loadCommentedRoutes();
    setState(() {
      _futureCommentedRoutes = f;
    });
    _futureCommentedRoutes.then((routes) {
      if (mounted) setState(() {
        _cachedRoutes = routes;
        _hasLoadedOnce = true;
      });
    });
    await _futureCommentedRoutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Yorumlarım",
        showBackButton: true,
        onBackButtonPressed: () => Navigator.pop(context),
        showAvatar: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<SharedRouteResponse>>(
          future: _futureCommentedRoutes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !_hasLoadedOnce) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && !_hasLoadedOnce) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  Center(child: Text("Hata: ${snapshot.error}")),
                ],
              );
            }

            final routes = snapshot.hasData ? snapshot.data! : (_cachedRoutes ?? []);

            if (routes.isEmpty) {
              return const Center(
                child: Text(
                  "Henüz yorum yaptığın bir paylaşım yok 💬",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                return SharedRouteCard(
                  sharedRoute: routes[index],
                  isOwner: _currentUserId == routes[index].userId,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
