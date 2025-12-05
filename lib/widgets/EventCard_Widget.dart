import 'package:cift_teker_front/screens/GroupEvent/event_detail_page.dart';
import 'package:flutter/material.dart';
import '../models/responses/groupEvent_response.dart';

class EventCard extends StatelessWidget {
  final GroupEventResponse event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
        );
      },
      child: Card(
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
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        event.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "${event.startDateTime} - ${event.endDateTime}",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "${event.startLocation} → ${event.endLocation}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (event.description != null)
                Text(
                  event.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "${event.maxParticipants} katılımcı",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
