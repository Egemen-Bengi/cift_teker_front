import 'package:flutter/material.dart';
import '../models/responses/sharedRoute_response.dart';

class SharedRouteCard extends StatelessWidget {
  final SharedRouteResponse sharedRoute;

  const SharedRouteCard({super.key, required this.sharedRoute});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      sharedRoute.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              sharedRoute.routeName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            if (sharedRoute.description != null)
              Text(
                sharedRoute.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  sharedRoute.imageUrl != null &&
                      sharedRoute.imageUrl!.isNotEmpty
                  ? Image.network(sharedRoute.imageUrl!, fit: BoxFit.cover)
                  : Image.asset("assets/ciftTeker.png", fit: BoxFit.cover),
            ),

            const SizedBox(height: 10),

            Text(
              "Paylaşım: ${sharedRoute.createdAt.toLocal()}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
