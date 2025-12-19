import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/responses/sharedRoute_response.dart';

class SharedRouteCard extends StatelessWidget {
  final SharedRouteResponse sharedRoute;

  const SharedRouteCard({super.key, required this.sharedRoute});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(sharedRoute.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        sharedRoute.username,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: Colors.grey[700]),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              sharedRoute.routeName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),

            const SizedBox(height: 6),

            if (sharedRoute.description != null)
              Text(
                sharedRoute.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  sharedRoute.imageUrl != null &&
                      sharedRoute.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: sharedRoute.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        "assets/ciftTeker.png",
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      "assets/ciftTeker.png",
                      height: 200,
                      fit: BoxFit.cover,
                    ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  "Paylaşım: $createdAt",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(icon: Icons.favorite_border, label: "Beğen"),
                _ActionButton(icon: Icons.chat_bubble_outline, label: "Yorum"),
                _ActionButton(icon: Icons.bookmark_border, label: "Kaydet"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.orange.shade700),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
