import 'package:cift_teker_front/screens/GroupEvent/event_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/responses/groupEvent_response.dart';
import '../models/responses/groupEventParticipant_response.dart';
import '../services/groupEventParticipant_service.dart';

class EventCard extends StatelessWidget {
  final GroupEventResponse event;
  final String? token;

  const EventCard({super.key, required this.event, this.token});

  @override
  Widget build(BuildContext context) {
    
    final start = DateFormat('dd MMM yyyy, HH:mm').format(event.startDateTime);
    final end = DateFormat('dd MMM yyyy, HH:mm').format(event.endDateTime);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
        );
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
              /// USERNAME + MENU ICON
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          event.username,
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
                  Icon(Icons.calendar_today,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "$start — $end",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// LOCATION
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: Colors.orange.shade700),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),

              const SizedBox(height: 12),

              /// PARTICIPANTS
              Row(
                children: [
                  Icon(Icons.people_alt_outlined,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  FutureBuilder<List<GroupEventParticipantResponse>>(
                    future: GroupEventParticipantService()
                        .getParticipants(event.groupEventId, token),
                    builder: (context, snapshot) {
                      String display;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        display = '...';
                      } else if (snapshot.hasError) {
                        debugPrint('getParticipants error: ${snapshot.error}');
                        final err = snapshot.error.toString();
                        if (err.contains('403') || err.toLowerCase().contains('forbidden')) {
                          display = 'Giriş gerekli';
                        } else {
                          final count = snapshot.data?.length ?? 0;
                          display = '$count';
                        }
                      } else {
                        final count = snapshot.data?.length ?? 0;
                        display = '$count';
                      }
                      return Text(
                        "$display / ${event.maxParticipants} katılımcı",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
