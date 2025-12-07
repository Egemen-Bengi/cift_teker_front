class UpdateUsernameResponse {
  final int userId;
  final String username;
  final String token;

  UpdateUsernameResponse({
    required this.userId,
    required this.username,
    required this.token,
  });

  factory UpdateUsernameResponse.fromJson(Map<String, dynamic> json) {
    return UpdateUsernameResponse(
      userId: json["userId"],
      username: json["username"],
      token: json["token"],
    );
  }
}
