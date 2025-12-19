import 'package:cift_teker_front/models/responses/sharedRoute_response.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharedRouteDetailPage extends StatefulWidget {
  final int sharedRouteId;

  const SharedRouteDetailPage({super.key, required this.sharedRouteId});

  @override
  State<SharedRouteDetailPage> createState() => _SharedRouteDetailPageState();
}

class _SharedRouteDetailPageState extends State<SharedRouteDetailPage> {
  final SharedRouteService _sharedRouteService = SharedRouteService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<SharedRouteResponse> _futureRoute;

  @override
  void initState() {
    super.initState();
    _futureRoute = _loadRoute();
  }

  Future<SharedRouteResponse> _loadRoute() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      throw Exception("Token bulunamadı");
    }

    return _sharedRouteService.getSharedRouteById(widget.sharedRouteId, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Rota Detayı",
        showBackButton: true,
        onBackButtonPressed: () => Navigator.pop(context),
        showAvatar: false,
      ),
      body: FutureBuilder<SharedRouteResponse>(
        future: _futureRoute,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final route = snapshot.data!;
          final createdAt = DateFormat(
            "dd MMM yyyy • HH:mm",
          ).format(route.createdAt);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        route.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        createdAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                route.imageUrl != null && route.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: route.imageUrl!,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          height: 280,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          "assets/ciftTeker.png",
                          height: 280,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        "assets/ciftTeker.png",
                        height: 280,
                        fit: BoxFit.cover,
                      ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: const [
                      _ActionIcon(icon: Icons.favorite_border),
                      SizedBox(width: 16),
                      _ActionIcon(icon: Icons.chat_bubble_outline),
                      SizedBox(width: 16),
                      _ActionIcon(icon: Icons.bookmark_border),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    route.routeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (route.description != null && route.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      route.description!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;

  const _ActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 28, color: Colors.orange.shade700);
  }
}
