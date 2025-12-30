import 'dart:io';

import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/requests/updatePassword_request.dart';
import 'package:cift_teker_front/models/requests/updateProfileImage_request.dart';
import 'package:cift_teker_front/models/requests/updateUsername_request.dart';
import 'package:cift_teker_front/models/requests/updateEmail_request.dart';
import 'package:cift_teker_front/models/requests/updatePhoneNumber_request.dart';
import 'package:cift_teker_front/models/responses/user_response.dart';
import 'package:cift_teker_front/screens/auth_screen.dart';
import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:cift_teker_front/services/login_service.dart';
import 'package:cift_teker_front/services/user_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cift_teker_front/screens/like_page.dart';
import 'package:cift_teker_front/screens/comment_page.dart';
import 'package:cift_teker_front/screens/record_page.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Future<ApiResponse<UserResponse>> _futureUser;

  @override
  void initState() {
    super.initState();
    _futureUser = _loadUser();
  }

  void _goBackToHome() {
    final mainNavState = context.findAncestorStateOfType<MainNavigationState>();
    mainNavState?.onItemTapped(0);
  }

  Future<void> _showAlertDialog(String title, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<ApiResponse<UserResponse>> _loadUser() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      return Future.error("Kullanıcı doğrulaması başarısız.");
    }

    return _userService.getMyInfo(token);
  }

  void _updateUsername(UserResponse user) {
    final usernameController = TextEditingController(text: user.username);

    showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("Kullanıcı Adını Güncelle"),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Yeni kullanıcı adı",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(alertContext);
            },
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              if (newUsername.isEmpty) {
                Navigator.pop(alertContext);
                _showAlertDialog("Hata", "Kullanıcı adı boş olamaz.");
                return;
              }

              BuildContext? loadingContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingContext = ctx;
                  return const Center(child: CircularProgressIndicator());
                },
              );

              final token = await _storage.read(key: "auth_token");

              if (token == null || token.isEmpty) {
                if (loadingContext != null) Navigator.pop(loadingContext!);
                Navigator.pop(alertContext);
                _showAlertDialog("Hata", "Oturum bulunamadı.");
                return;
              }

              try {
                final updateResponse = await _userService.updateUsername(
                  UpdateUsernameRequest(newUsername: newUsername),
                  token,
                );

                if (loadingContext != null) Navigator.pop(loadingContext!);

                String title, message;
                if (updateResponse.message.toLowerCase().contains("success") ||
                    updateResponse.httpStatus == "200") {
                  setState(() {
                    _futureUser = _loadUser();
                  });
                  title = "Başarılı";
                  message = "Kullanıcı adınız güncellendi.";
                } else {
                  title = "Hata";
                  message =
                      "Kullanıcı adı güncellenemedi: ${updateResponse.message}";
                }

                Navigator.pop(alertContext);

                await Future.delayed(const Duration(milliseconds: 100));

                _showAlertDialog(title, message);
              } catch (e) {
                if (loadingContext != null) Navigator.pop(loadingContext!);
                Navigator.pop(alertContext);
                _showAlertDialog(
                  "Hata",
                  "Güncelleme sırasında hata: ${e.toString()}",
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    ).then((_) {});
  }

  void _updatePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Şifre Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Eski Şifre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Yeni Şifre",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            child: const Text("Değiştir"),
            onPressed: () async {
              final oldPass = oldPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();

              if (oldPass.isEmpty || newPass.isEmpty) {
                Navigator.pop(dialogContext);
                _showAlertDialog("Hata", "Alanlar boş bırakılamaz.");
                return;
              }

              Navigator.pop(dialogContext);

              BuildContext? loadingDialogContext;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingDialogContext = ctx;
                  return const Center(child: CircularProgressIndicator());
                },
              );

              final token = await _storage.read(key: "auth_token");

              if (token == null) {
                if (loadingDialogContext != null) {
                  Navigator.pop(loadingDialogContext!);
                }
                _showAlertDialog("Hata", "Token bulunamadı.");
                return;
              }

              try {
                final loginService = LoginService();

                await loginService.updatePassword(
                  UpdatePasswordRequest(
                    oldPassword: oldPass,
                    newPassword: newPass,
                  ),
                  token,
                );

                await _storage.delete(key: "auth_token");

                if (loadingDialogContext != null) {
                  Navigator.pop(loadingDialogContext!);
                }

                await _showAlertDialog(
                  "Başarılı",
                  "Şifre değiştirildi. Yeniden giriş yapmanız gerekiyor.",
                );

                if (!mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                if (loadingDialogContext != null) {
                  Navigator.pop(loadingDialogContext!);
                }

                if (mounted) {
                  _showAlertDialog("Hata", "İşlem başarısız: ${e.toString()}");
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void updateEmail(UserResponse user) {
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("E-posta Güncelle"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Yeni e-posta",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(alertContext);
            },
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty) {
                Navigator.pop(alertContext);
                _showAlertDialog("Hata", "E-posta boş olamaz.");
                return;
              }

              BuildContext? loadingContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingContext = ctx;
                  return const Center(child: CircularProgressIndicator());
                },
              );

              final token = await _storage.read(key: "auth_token");

              if (token == null || token.isEmpty) {
                if (loadingContext != null && mounted)
                  Navigator.pop(loadingContext!);
                Navigator.pop(alertContext);
                _showAlertDialog("Hata", "Oturum bulunamadı.");
                return;
              }

              try {
                final updateResponse = await _userService.updateEmail(
                  UpdateEmailRequest(newEmail: newEmail),
                  token,
                );

                if (loadingContext != null && mounted)
                  Navigator.pop(loadingContext!);

                String title, message;
                if (updateResponse.message.toLowerCase().contains("success") ||
                    updateResponse.httpStatus == "200") {
                  setState(() {
                    _futureUser = _loadUser();
                  });
                  title = "Başarılı";
                  message = "E-postanız güncellendi.";
                } else {
                  title = "Hata";
                  message = "E-posta güncellenemedi: ${updateResponse.message}";
                }

                Navigator.pop(alertContext);

                await Future.delayed(const Duration(milliseconds: 100));

                _showAlertDialog(title, message);
              } catch (e) {
                if (loadingContext != null && mounted)
                  Navigator.pop(loadingContext!);
                Navigator.pop(alertContext);
                _showAlertDialog(
                  "Hata",
                  "Güncelleme sırasında hata: ${e.toString()}",
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    ).then((_) {});
  }

  void updatePhoneNumber(UserResponse user) {
    final phoneNumberController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        title: const Text("Telefon Numarası Güncelle"),
        content: TextField(
          controller: phoneNumberController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Yeni telefon numarası",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(alertContext);
            },
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhoneNumber = phoneNumberController.text.trim();
              if (newPhoneNumber.isEmpty) {
                Navigator.pop(alertContext);
                _showAlertDialog("Hata", "Telefon numarası boş olamaz.");
                return;
              }

              BuildContext? loadingContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  loadingContext = ctx;
                  return const Center(child: CircularProgressIndicator());
                },
              );

              final token = await _storage.read(key: "auth_token");

              if (token == null || token.isEmpty) {
                if (loadingContext != null && mounted)
                  Navigator.pop(loadingContext!);
                Navigator.pop(alertContext);
                _showAlertDialog("Hata", "Oturum bulunamadı.");
                return;
              }

              try {
                final updateResponse = await _userService.updatePhoneNumber(
                  UpdatePhoneNumberRequest(newPhoneNumber: newPhoneNumber),
                  token,
                );

                if (loadingContext != null && mounted)
                  Navigator.pop(loadingContext!);

                String title, message;
                if (updateResponse.message.toLowerCase().contains("success") ||
                    updateResponse.httpStatus == "200") {
                  setState(() {
                    _futureUser = _loadUser();
                  });
                  title = "Başarılı";
                  message = "Telefon numaranız güncellendi.";
                } else {
                  title = "Hata";
                  message =
                      "Telefon numarası güncellenemedi: ${updateResponse.message}";
                }

                Navigator.pop(alertContext);

                await Future.delayed(const Duration(milliseconds: 100));

                _showAlertDialog(title, message);
              } catch (e) {
                if (loadingContext != null && mounted)
                  Navigator.pop(loadingContext!);
                Navigator.pop(alertContext);
                _showAlertDialog(
                  "Hata",
                  "Güncelleme sırasında hata: ${e.toString()}",
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    ).then((_) {});
  }

  void _showProfileImageOptions(UserResponse user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Fotoğraf Çek"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadProfileImage(ImageSource.camera, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galeriden Seç"),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadProfileImage(ImageSource.gallery, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadProfileImage(
    ImageSource source,
    UserResponse user,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      BuildContext? loadingContext;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          loadingContext = ctx;
          return const Center(child: CircularProgressIndicator());
        },
      );

      final token = await _storage.read(key: "auth_token");
      if (token == null) throw "Oturum bulunamadı.";

      String safeUsername = user.username
          .toLowerCase()
          .replaceAll(" ", "_")
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');

      final fileName = DateTime.now().toIso8601String().replaceAll(":", "-");

      final ref = FirebaseStorage.instance.ref(
        'profile_images/$safeUsername/$fileName.png',
      );

      final snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/png'),
      );

      final imageUrl = await snapshot.ref.getDownloadURL();

      await _userService.updateProfileImage(
        UpdateProfileImageRequest(newProfileImage: imageUrl),
        token,
      );

      if (loadingContext != null && mounted) {
        Navigator.pop(loadingContext!);
      }

      setState(() {
        _futureUser = _loadUser();
      });

      _showAlertDialog("Başarılı", "Profil fotoğrafı güncellendi 🎉");
    } catch (e) {
      Navigator.pop(context);
      _showAlertDialog("Hata", e.toString());
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Çıkış yapmak istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);

              await _storage.delete(key: "auth_token");

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage()),
              );
            },
            child: const Text("Evet, Çıkış Yap"),
          ),
        ],
      ),
    );
  }

  // Bilgileri gösteren satır widget
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar BottomNav ile uyumlu şekilde sade tutuldu
      appBar: CustomAppBar(
        title: "Profil",
        showBackButton: true,
        onBackButtonPressed: _goBackToHome,
        showAvatar: false,
      ),
      body: FutureBuilder<ApiResponse<UserResponse>>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text("Hata: ${snapshot.error ?? "Bilinmeyen hata"}"),
            );
          }

          final user = snapshot.data!.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // PROFIL FOTOĞRAFI
                GestureDetector(
                  onTap: () => _showProfileImageOptions(user),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : const AssetImage("assets/ciftTeker.png")
                              as ImageProvider,
                  ),
                ),

                const SizedBox(height: 20),

                // İSİM + SOYİSİM
                Text(
                  "${user.name} ${user.surname}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  user.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // PROFİL BİLGİLERİ KARTI
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow("Kullanıcı Adı", user.username),
                      const Divider(),
                      _infoRow("Mail Adresi", user.email),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Kullanıcı adı güncelle butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateUsername(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Kullanıcı Adını Güncelle",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                // E-posta güncelle butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => updateEmail(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "E-posta Güncelle",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                // Şifre güncelle butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Şifreyi Değiştir",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                //  Telefon numarası güncelle butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => updatePhoneNumber(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Telefon Numarasını Güncelle",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Etkileşimlerim",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _interactionButton(
                        icon: Icons.favorite,
                        title: "Beğenilerim",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LikePage()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _interactionButton(
                        icon: Icons.chat_bubble_outline,
                        title: "Yorumlarım",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommentPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _interactionButton(
                        icon: Icons.bookmark,
                        title: "Kaydedilenler",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecordPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Çıkış Yap",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _interactionButton({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color color = Colors.orange,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );
}
