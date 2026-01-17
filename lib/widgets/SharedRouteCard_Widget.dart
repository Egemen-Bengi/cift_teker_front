import 'package:cift_teker_front/components/UserChip.dart';
import 'package:cift_teker_front/models/responses/comment_response.dart';
import 'package:cift_teker_front/models/responses/like_response.dart';
import 'package:cift_teker_front/models/responses/record_response.dart';
import 'package:cift_teker_front/screens/editSharedRoute_page.dart';
import 'package:cift_teker_front/services/comment_service.dart';
import 'package:cift_teker_front/services/like_service.dart';
import 'package:cift_teker_front/services/record_service.dart';
import 'package:cift_teker_front/services/sharedRoute_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/responses/sharedRoute_response.dart';

class SharedRouteCard extends StatefulWidget {
  final SharedRouteResponse sharedRoute;
  final LikeResponse? myLike;
  final RecordResponse? myRecord;
  final bool isDetail;
  final bool isOwner;
  final VoidCallback? onChanged;

  const SharedRouteCard({
    super.key,
    required this.sharedRoute,
    this.myLike,
    this.myRecord,
    this.isDetail = false,
    required this.isOwner,
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
  final SharedRouteService _sharedRouteService = SharedRouteService();

  List<CommentResponse> comments = [];
  bool isLoadingComments = false;

  late bool isLiked;
  late bool isRecorded;

  int? selectedParentId;
  String? selectedUsername;
  int? selectedParentRootId;

  bool showCommentBox = false;
  final TextEditingController _commentController = TextEditingController();

  int _likeCount = 0;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    isLiked = widget.myLike != null;
    isRecorded = widget.myRecord != null;
    _loadLikeCount();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token != null) {
        final decoded = JwtDecoder.decode(token);
        final int userId = decoded["userId"];

        if (mounted) {
          setState(() {
            _currentUserId = userId;
          });
        }
      }
    } catch (e) {
      debugPrint("Kullanıcı ID yüklenirken hata: $e");
    }
  }

  Future<void> _loadLikeCount() async {
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;
      final response = await _likeService.getLikeCount(
        widget.sharedRoute.sharedRouteId,
        token,
      );
      if (mounted) {
        setState(() {
          _likeCount = response.data;
        });
      }
    } catch (e) {
      debugPrint("Like count error: $e");
    }
  }

  Future<void> _toggleLike() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    await _likeService.toggleLike(widget.sharedRoute.sharedRouteId, token);

    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
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

  Future<void> _loadComments() async {
    setState(() => isLoadingComments = true);
    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;
      final response = await _commentService.getCommentsByRoute(
        widget.sharedRoute.sharedRouteId,
        token,
      );
      setState(() {
        comments = response.data;
        isLoadingComments = false;
      });
    } catch (e) {
      setState(() => isLoadingComments = false);
    }
  }

  Future<void> _deleteMyComment(
    int commentId,
    StateSetter setModalState,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Yorumu Sil"),
        content: const Text("Bu yorumu silmek istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) return;

      await _commentService.deleteComment(commentId, token);

      if (mounted) {
        Navigator.pop(context);

        _loadComments();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Yorum silindi."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _loadComments();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("İşlem tamamlandı: $e")));
      }
    }
  }

  void _showCommentsSheet() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    final response = await _commentService.getCommentsByRoute(
      widget.sharedRoute.sharedRouteId,
      token,
    );
    comments = response.data;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final sortedComments = _sortComments(comments);

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    "Yorumlar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),

                  Expanded(
                    child: sortedComments.isEmpty
                        ? const Center(child: Text("Henüz yorum yapılmamış."))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: sortedComments.length,
                            itemBuilder: (context, index) {
                              final comment = sortedComments[index];
                              final isReply = comment.parentCommentId != null;

                              final isMyComment =
                                  _currentUserId != null &&
                                  comment.userId == _currentUserId;

                              return Padding(
                                padding: EdgeInsets.only(
                                  left: isReply ? 45.0 : 0.0,
                                  right: isReply ? 10.0 : 0.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isReply
                                        ? Colors.grey[50]
                                        : Colors.transparent,
                                    border: isReply
                                        ? Border(
                                            left: BorderSide(
                                              color: Colors.orange.shade200,
                                              width: 2,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange.shade100,
                                      child: Text(
                                        comment.username.isNotEmpty
                                            ? comment.username[0].toUpperCase()
                                            : "?",
                                      ),
                                    ),
                                    title: Text(
                                      "${comment.username}${isReply ? ' (Yanıtladı)' : ''}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isReply ? 12 : 13,
                                        color: isReply
                                            ? Colors.grey[600]
                                            : Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(comment.content),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setModalState(() {
                                                  selectedParentId =
                                                      comment.commentId;
                                                  selectedParentRootId =
                                                      comment.parentCommentId ??
                                                      comment.commentId;
                                                  selectedUsername =
                                                      comment.username;
                                                });
                                              },
                                              child: const Text(
                                                "Yanıtla",
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            if (isMyComment) ...[
                                              const SizedBox(width: 15),
                                              GestureDetector(
                                                onTap: () {
                                                  _deleteMyComment(
                                                    comment.commentId,
                                                    setModalState,
                                                  );
                                                },
                                                child: const Text(
                                                  "Sil",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      DateFormat(
                                        'dd.MM HH:mm',
                                      ).format(comment.createdAt),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  if (selectedParentId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "$selectedUsername kişisine yanıt veriliyor...",
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setModalState(() {
                              selectedParentId = null;
                              selectedUsername = null;
                            }),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                      left: 10,
                      right: 10,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            autofocus: selectedParentId != null,
                            decoration: InputDecoration(
                              hintText: selectedParentId == null
                                  ? "Yorum ekle..."
                                  : "Yanıtınızı yazın...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.orange),
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            await _sendReplyComment();

                            if (mounted) {
                              Navigator.pop(context);

                              _loadComments();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Yorum gönderildi."),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              setState(() {
                                selectedParentId = null;
                                selectedParentRootId = null;
                                selectedUsername = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendReplyComment() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null || _commentController.text.trim().isEmpty) return;

    final Map<String, dynamic> commentData = {
      "sharedRouteId": widget.sharedRoute.sharedRouteId,
      "content": _commentController.text,
    };

    if (selectedParentRootId != null) {
      commentData["parentCommentId"] = selectedParentRootId;
    }

    await _commentService.saveComment(commentData, token);

    _commentController.clear();
  }

  List<CommentResponse> _sortComments(List<CommentResponse> rawComments) {
    List<CommentResponse> sorted = [];

    var mainComments = rawComments
        .where((c) => c.parentCommentId == null)
        .toList();

    mainComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (var main in mainComments) {
      sorted.add(main);

      var replies = rawComments
          .where((c) => c.parentCommentId == main.commentId)
          .toList();

      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      sorted.addAll(replies);
    }

    return sorted;
  }

  Future<void> _goToEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSharedRoutePage(sharedRoute: widget.sharedRoute),
      ),
    );

    if (result == true) {
      widget.onChanged?.call();
    }
  }

  Future<void> _confirmDelete() async {
    final bool? approved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Paylaşımı Sil"),
        content: const Text(
          "Bu paylaşımı silmek istediğine emin misin? Bu işlem geri alınamaz.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (approved != true) return;

    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    await _sharedRouteService.deleteSharedRoute(
      widget.sharedRoute.sharedRouteId,
      token,
    );

    widget.onChanged?.call();

    if (widget.isDetail && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showLikesSheet() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null) return;

    final response = await _likeService.getLikesByRoute(
      widget.sharedRoute.sharedRouteId,
      token,
    );
    final likers = response.data;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                "Beğenenler",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              Expanded(
                child: likers.isEmpty
                    ? const Center(child: Text("Henüz beğenen kimse yok."))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: likers.length,
                        itemBuilder: (context, index) {
                          final liker = likers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red[100],
                              child: Text(
                                liker.username.isNotEmpty
                                    ? liker.username[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            title: Text(
                              liker.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
                UserChip(username: widget.sharedRoute.username),
                if (widget.isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _goToEditPage();
                      } else if (value == 'delete') {
                        _confirmDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text("Düzenle")),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text("Sil", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
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

            /// STATS
            if (_likeCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: GestureDetector(
                  onTap: _showLikesSheet,
                  child: Text(
                    "$_likeCount beğeni",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),

            const Divider(height: 1),
            const SizedBox(height: 4),

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
                  label: "Yorumlar",
                  active: false,
                  onTap: _showCommentsSheet,
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
              const Divider(height: 32),

              if (isLoadingComments)
                const Center(child: CircularProgressIndicator())
              else if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Henüz yorum yok, ilk yorumu sen yap!",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "${comment.userId} ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: comment.content),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Az önce",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Yorum ekle...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.orange),
                    onPressed: () async {
                      await _sendComment();
                      _loadComments();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ],
        ),
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
