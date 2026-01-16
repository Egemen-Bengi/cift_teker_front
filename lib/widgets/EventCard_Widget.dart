import 'package:cift_teker_front/components/UserChip.dart';
import 'package:cift_teker_front/screens/GroupEvent/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/responses/groupEvent_response.dart';

class EventCard extends StatelessWidget {
  final GroupEventResponse event;
  final String? token;

  final VoidCallback? onUpdated;

  const EventCard({super.key, required this.event, this.token, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final start = DateFormat('dd MMM yyyy, HH:mm').format(event.startDateTime);
    final end = DateFormat('dd MMM yyyy, HH:mm').format(event.endDateTime);

    return GestureDetector(
      onTap: () async {
        final updatedEvent = await Navigator.push<GroupEventResponse>(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
        );

        if (updatedEvent != null && onUpdated != null) {
          onUpdated!();
        }
      },
      child: Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// USERNAME
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  UserChip(username: event.username),
                  Icon(Icons.more_vert, color: Colors.grey[700]),
                ],
              ),
              const SizedBox(height: 14),

              /// TITLE
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),

              const SizedBox(height: 6),

              /// DATE RANGE
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "$start — $end",
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// LOCATION
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "${event.startLocation} → ${event.endLocation}   /  ${event.city}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// DESCRIPTION
              if (event.description != null)
                Text(
                  event.description!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),

              const SizedBox(height: 12),

              /// PARTICIPANTS (SENİN KODUN – DEĞİŞMEDİ)
              Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${event.currentParticipants ?? 0} / ${event.maxParticipants} katılımcı",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
