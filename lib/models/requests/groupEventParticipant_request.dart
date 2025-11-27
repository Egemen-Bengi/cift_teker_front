class GroupEventParticipantRequest {
  final int groupEventId;

  GroupEventParticipantRequest({required this.groupEventId});

  Map<String, dynamic> toJson() {
    return {"groupEventId": groupEventId};
  }
}
