import 'package:cift_teker_front/models/responses/like_response.dart';
import 'package:cift_teker_front/models/responses/record_response.dart';
import 'package:cift_teker_front/services/comment_service.dart';
import 'package:cift_teker_front/services/like_service.dart';
import 'package:cift_teker_front/services/record_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/responses/sharedRoute_response.dart';

class SharedRouteCard extends StatefulWidget {
  final SharedRouteResponse sharedRoute;
  final LikeResponse? myLike;
  final RecordResponse? myRecord;
  final bool isDetail;
  final VoidCallback? onChanged;

  const SharedRouteCard({
    super.key,
    required this.sharedRoute,
    this.myLike,
    this.myRecord,
    this.isDetail = false,
    this.onChanged,
  });

  @override
  State<SharedRouteCard> createState() => _SharedRouteCardState();
}

class _SharedRouteCardState extends State<SharedRouteCard> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LikeService _likeService = LikeService();
  final RecordService _recordService = RecordService();
  final CommentService _commentService = CommentService();

  late bool isLiked;
  late bool isRecorded;

  int? likeId;
  int? recordId;

  bool showCommentBox = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLiked = widget.myLike != null;
    isRecorded = widget.myRecord != null;
    likeId = widget.myLike?.likeId;
    recordId = widget.myRecord?.recordId;
  }

  Future<void> _toggleLike() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    await _likeService.toggleLike(widget.sharedRoute.sharedRouteId, token);

    setState(() {
      isLiked = !isLiked;
    });
    widget.onChanged?.call();
  }

  Future<void> _toggleRecord() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    await _recordService.toggleRecord(widget.sharedRoute.sharedRouteId, token);

    setState(() {
      isRecorded = !isRecorded;
    });
    widget.onChanged?.call();
  }

  Future<void> _sendComment() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null || _commentController.text.trim().isEmpty) return;

    await _commentService.saveComment({
      "sharedRouteId": widget.sharedRoute.sharedRouteId,
      "content": _commentController.text,
    }, token);

    _commentController.clear();
    setState(() {
      showCommentBox = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(widget.sharedRoute.createdAt);

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
            /// USER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _UserChip(username: widget.sharedRoute.username),
                Icon(Icons.more_vert, color: Colors.grey[700]),
              ],
            ),

            const SizedBox(height: 14),

            /// ROUTE NAME
            Text(
              widget.sharedRoute.routeName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),

            if (widget.sharedRoute.description != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.sharedRoute.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],

            const SizedBox(height: 12),

            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  widget.sharedRoute.imageUrl != null &&
                      widget.sharedRoute.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.sharedRoute.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => Image.asset(
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

            const SizedBox(height: 10),

            /// DATE
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

            /// ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  activeIcon: Icons.favorite,
                  inactiveIcon: Icons.favorite_border,
                  label: "Beğen",
                  active: isLiked,
                  onTap: _toggleLike,
                ),

                _ActionButton(
                  activeIcon: Icons.chat_bubble,
                  inactiveIcon: Icons.chat_bubble_outline,
                  label: "Yorum",
                  active: showCommentBox,
                  onTap: () {
                    setState(() {
                      showCommentBox = !showCommentBox;
                    });
                  },
                ),

                _ActionButton(
                  activeIcon: Icons.bookmark,
                  inactiveIcon: Icons.bookmark_border,
                  label: "Kaydet",
                  active: isRecorded,
                  onTap: _toggleRecord,
                ),
              ],
            ),

            /// COMMENT BOX
            if (showCommentBox) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: "Yorum yaz...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _sendComment,
                  child: const Text("Gönder"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String username;
  const _UserChip({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            username,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ActionButton({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.red : Colors.orange.shade700;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(active ? activeIcon : inactiveIcon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
