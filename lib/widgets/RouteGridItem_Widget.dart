import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/responses/sharedRoute_response.dart';

class RouteGridItem extends StatelessWidget {
  final SharedRouteResponse route;
  final VoidCallback onTap;

  const RouteGridItem({super.key, required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: route.imageUrl != null && route.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: route.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[300]),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/ciftTeker.png",
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset("assets/ciftTeker.png", fit: BoxFit.cover),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.routeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    route.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
