class UpdateProfileImageRequest {
  final String newProfileImage;

  UpdateProfileImageRequest({required this.newProfileImage});

  Map<String, dynamic> toJson() {
    return {
      "newProfileImage": newProfileImage,
    };
  }
}
