class UpdateEmailRequest {
  String newEmail;
  UpdateEmailRequest({required this.newEmail});

  Map<String, dynamic> toJson() {
    return {
      'newEmail': newEmail,
    };
  }
}