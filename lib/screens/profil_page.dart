import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/requests/updateUsername_request.dart';
import 'package:cift_teker_front/models/responses/user_response.dart';
import 'package:cift_teker_front/services/user_service.dart';
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
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await _storage.read(key: "auth_token");

    if (token == null || token.isEmpty) {
      return mounted
          ? setState(() {
              _futureUser = Future.error("Kullanıcı doğrulaması başarısız.");
            })
          : null;
    }

    setState(() {
      _futureUser = _userService.getMyInfo(token);
    });
  }

  void _updateUsername(UserResponse user) {
    final usernameController = TextEditingController(text: user.username);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final newUsername = usernameController.text.trim();
              final token = await _storage.read(key: "auth_token");
              if (token == null) return;

              try {
                await _userService.updateUsername(
                  UpdateUsernameRequest(newUsername: newUsername),
                  token,
                );
                _loadUser();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kullanıcı adı güncellendi!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Hata: $e")));
              }
            },
            child: const Text("Güncelle"),
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
      appBar: AppBar(
        title: const Text(
          "Profil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
