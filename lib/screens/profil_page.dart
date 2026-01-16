import 'dart:io';

import 'package:cift_teker_front/components/FullScreenImagePage.dart';
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

  Future<ApiResponse<UserResponse>> _loadUser() async {
    final token = await _storage.read(key: "auth_token");
    if (token == null || token.isEmpty) {
      return Future.error("Oturum bulunamadı.");
    }
    return _userService.getMyInfo(token);
  }

  Future<void> _genericUpdateDialog({
    required String title,
    required String label,
    required String initialValue,
    required Future<ApiResponse> Function(String val, String token) onUpdate,
  }) async {
    final controller = TextEditingController(text: initialValue);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) return;

              Navigator.pop(ctx);
              _handleUpdateProcess(() async {
                final token = await _storage.read(key: "auth_token");
                if (token == null) throw "Token bulunamadı";
                return onUpdate(value, token);
              });
            },
            child: const Text(
              "Güncelle",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdateProcess(
    Future<ApiResponse> Function() action,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      final response = await action();

      if (!mounted) return;
      Navigator.pop(context);

      if (response.httpStatus == "200" ||
          response.message.toLowerCase().contains("success")) {
        setState(() {
          _futureUser = _loadUser();
        });
        _showSnack(Colors.green, "İşlem başarılı! ✅");
      } else {
        _showSnack(Colors.red, "Hata: ${response.message}");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack(Colors.red, "Bir hata oluştu: $e");
    }
  }

  void _showSnack(Color color, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _updatePassword() {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Şifre Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Eski Şifre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (oldController.text.isEmpty || newController.text.isEmpty)
                return;
              Navigator.pop(ctx);

              _handlePasswordChangeProcess(
                oldController.text,
                newController.text,
              );
            },
            child: const Text("Değiştir"),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePasswordChangeProcess(
    String oldPass,
    String newPass,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await _storage.read(key: "auth_token");
      if (token == null) throw "Oturum yok";

      final loginService = LoginService();
      await loginService.updatePassword(
        UpdatePasswordRequest(oldPassword: oldPass, newPassword: newPass),
        token,
      );

      await _storage.delete(key: "auth_token");

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );

      _showSnack(Colors.green, "Şifre değişti, lütfen tekrar giriş yapın.");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack(Colors.red, "Hata: $e");
    }
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

      _handleUpdateProcess(() async {
        final token = await _storage.read(key: "auth_token");

        String safeUsername = user.username.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9_]'),
          '',
        );
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.png";

        final ref = FirebaseStorage.instance.ref(
          'profile_images/$safeUsername/$fileName',
        );
        final snapshot = await ref.putFile(
          File(pickedFile.path),
          SettableMetadata(contentType: 'image/png'),
        );
        final imageUrl = await snapshot.ref.getDownloadURL();

        return _userService.updateProfileImage(
          UpdateProfileImageRequest(newProfileImage: imageUrl),
          token!,
        );
      });
    } catch (e) {
      _showSnack(Colors.red, "Resim yüklenemedi: $e");
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Çıkış yapmak istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<ApiResponse<UserResponse>>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Hata: ${snapshot.error ?? "Veri yok"}"));
          }

          final user = snapshot.data!.data;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.orange,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    context
                        .findAncestorStateOfType<MainNavigationState>()
                        ?.onItemTapped(0);
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade800,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImagePage(
                                      imageUrl: user.profileImage,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Hero(
                                  tag: 'profile_image_hero',
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundImage: user.profileImage != null
                                        ? NetworkImage(user.profileImage!)
                                        : const AssetImage(
                                                "assets/ciftTeker.png",
                                              )
                                              as ImageProvider,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showProfileImageOptions(user),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Text(
                          "${user.name} ${user.surname}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            "Beğeniler",
                            Icons.favorite,
                            Colors.red,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LikePage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            "Yorumlar",
                            Icons.chat_bubble,
                            Colors.blue,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CommentPage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            "Kaydedilen",
                            Icons.bookmark,
                            Colors.orange,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecordPage(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "Hesap Ayarları",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.person,
                              title: "Kullanıcı Adı",
                              value: user.username,
                              onTap: () => _genericUpdateDialog(
                                title: "Kullanıcı Adı Değiştir",
                                label: "Yeni Ad",
                                initialValue: user.username,
                                onUpdate: (val, token) =>
                                    _userService.updateUsername(
                                      UpdateUsernameRequest(newUsername: val),
                                      token,
                                    ),
                              ),
                            ),
                            const Divider(height: 1, indent: 60),
                            _buildSettingsTile(
                              icon: Icons.email,
                              title: "E-posta",
                              value: user.email,
                              onTap: () => _genericUpdateDialog(
                                title: "E-posta Değiştir",
                                label: "Yeni E-posta",
                                initialValue: user.email,
                                onUpdate: (val, token) =>
                                    _userService.updateEmail(
                                      UpdateEmailRequest(newEmail: val),
                                      token,
                                    ),
                              ),
                            ),
                            const Divider(height: 1, indent: 60),
                            _buildSettingsTile(
                              icon: Icons.phone,
                              title: "Telefon",
                              value: user.phoneNumber ?? "Belirtilmemiş",
                              onTap: () => _genericUpdateDialog(
                                title: "Telefon Değiştir",
                                label: "Yeni Numara",
                                initialValue: user.phoneNumber ?? "",
                                onUpdate: (val, token) =>
                                    _userService.updatePhoneNumber(
                                      UpdatePhoneNumberRequest(
                                        newPhoneNumber: val,
                                      ),
                                      token,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "Güvenlik",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.blue,
                                ),
                              ),
                              title: const Text(
                                "Şifre Değiştir",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: _updatePassword,
                            ),
                            const Divider(height: 1, indent: 60),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                              ),
                              title: const Text(
                                "Çıkış Yap",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.orange),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.edit, size: 16, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }
}
