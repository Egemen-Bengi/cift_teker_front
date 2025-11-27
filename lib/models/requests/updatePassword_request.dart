class UpdatePasswordRequest {
  final String oldPassword;
  final String newPassword;

  UpdatePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      };
}
// bu req classi login servis dosyasinda bulunan update password metodu icin yazildi