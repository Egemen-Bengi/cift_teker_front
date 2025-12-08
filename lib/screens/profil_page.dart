import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/requests/updateUsername_request.dart';
import 'package:cift_teker_front/models/responses/user_response.dart';
import 'package:cift_teker_front/screens/auth_screen.dart';
import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:cift_teker_front/services/user_service.dart';
import 'package:cift_teker_front/widgets/CustomAppBar_Widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  void _showAlertDialog(String title, String message) {
    showDialog(
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
                CircleAvatar(
                  radius: 80,
                  backgroundImage: user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : const AssetImage("assets/ciftTeker.png")
                            as ImageProvider,
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
