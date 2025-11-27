class GroupEventParticipantResponse {
  final int participantsId;
  final String status;
  final String username;
  final String joinedAt;
  final int groupEventId;
  final int userId;

  GroupEventParticipantResponse({
    required this.participantsId,
    required this.status,
    required this.username,
    required this.joinedAt,
    required this.groupEventId,
    required this.userId,
  });

  factory GroupEventParticipantResponse.fromJson(Map<String, dynamic> json) {
    return GroupEventParticipantResponse(
      participantsId: json["participantsId"],
      status: json["status"],
      username: json["username"],
      joinedAt: json["joinedAt"],
      groupEventId: json["groupEventId"],
      userId: json["userId"],
    );
  }
}
