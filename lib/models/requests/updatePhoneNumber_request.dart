class UpdatePhoneNumberRequest {
  String newPhoneNumber;
  UpdatePhoneNumberRequest({required this.newPhoneNumber});

  Map<String, dynamic> toJson() {
    return {
      'newPhoneNumber': newPhoneNumber,
    };
  }
}