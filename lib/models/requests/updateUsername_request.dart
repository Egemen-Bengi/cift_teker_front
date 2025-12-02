class UpdateUsernameRequest {
  final String newUsername;

  UpdateUsernameRequest({required this.newUsername});

  Map<String, dynamic> toJson() {
    return {
      "newUsername": newUsername,
    };
  }
}
