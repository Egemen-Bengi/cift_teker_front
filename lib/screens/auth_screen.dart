// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously

import 'package:cift_teker_front/models/requests/login_request.dart';
import 'package:cift_teker_front/models/requests/updatePassword_request.dart';
import 'package:cift_teker_front/services/login_service.dart';
import 'package:cift_teker_front/models/requests/user_request.dart';
import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:cift_teker_front/services/user_service.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignIn = true;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _usernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  bool _isMale = true;

  String _genderText(){
    return _isMale ? "male" : "female";
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[!@#\$%^&*(),.?":{}|<>]).{5,}$');
    return passwordRegex.hasMatch(password);
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

  void _submitSignUp() async {
    // Form validasyonu
    if (!_formKey.currentState!.validate()) {
      _showAlertDialog(
        "Eksik veya Hatalı Bilgi",
        "Lütfen tüm alanları doğru şekilde doldurun.",
      );
      return;
    }

    try {
      final userService = UserService();

      final request = UserRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _firstNameController.text.trim(),
        surname: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _genderText(),
      );

      // API çağrısı
      final response = await userService.saveUser(request, "/register/USER");

      if (!mounted) return;

      final welcomeName = response.data != null && response.data.username != null
          ? response.data.username
          : _usernameController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kayıt başarılı! Hoş geldin $welcomeName"),
        ),
      );

      // Başarılı kayıt sonrası ana ekrana yönlendir
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarısız: ${e.toString()}")),
      );
    }
  }

  // Giriş işlemini LoginService ile yapan fonksiyon
  void _submitSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showAlertDialog("Hata", "E-posta alanı boş olamaz.");
      return;
    }
    if (!_isValidEmail(email)) {
      _showAlertDialog("Hata", "Geçerli bir e-posta girin.");
      return;
    }
    if (password.isEmpty) {
      _showAlertDialog("Hata", "Şifre alanı boş olamaz.");
      return;
    }
    if (!_isValidPassword(password)) {
      _showAlertDialog(
        "Hata",
        "Şifre en az 5 karakter olmalı ve en az bir özel karakter içermelidir.",
      );
      return;
    }

    try {
      final loginService = LoginService();
      final resp = await loginService.login(
        LoginRequest(password: password, username: _usernameController.text.trim()),
      );

      if (!mounted) return;

      final userName = resp.data?.username ?? email;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giriş başarılı! Hoş geldin $userName")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Giriş başarısız: ${e.toString()}")),
      );
    }
  }

  // Şifremi unuttum dialog'u: token + eski şifre + yeni şifre alıp LoginService.updatePassword çağırır
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController tokenController = TextEditingController();
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şifre Güncelle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tokeniniz varsa girin. Eski şifrenizi ve yeni şifrenizi girin.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: "Token / Kod"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: oldPassController,
                decoration: const InputDecoration(labelText: "Eski Şifre"),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPassController,
                decoration: const InputDecoration(labelText: "Yeni Şifre"),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(labelText: "Yeni Şifre (Tekrar)"),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              final token = tokenController.text.trim();
              final oldPass = oldPassController.text;
              final newPass = newPassController.text;
              final confirm = confirmController.text;

              if (token.isEmpty) {
                _showAlertDialog("Hata", "Token boş olamaz.");
                return;
              }
              if (oldPass.isEmpty) {
                _showAlertDialog("Hata", "Eski şifre boş olamaz.");
                return;
              }
              if (newPass.isEmpty || confirm.isEmpty) {
                _showAlertDialog("Hata", "Yeni şifre alanları boş olamaz.");
                return;
              }
              if (newPass != confirm) {
                _showAlertDialog("Hata", "Şifreler eşleşmiyor.");
                return;
              }
              if (!_isValidPassword(newPass)) {
                _showAlertDialog("Hata", "Şifre en az 5 karakter ve özel karakter içermeli.");
                return;
              }

              try {
                final loginService = LoginService();
                final req = UpdatePasswordRequest(oldPassword: oldPass, newPassword: newPass);
                await loginService.updatePassword(req, token);

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Şifre başarıyla güncellendi.")),
                );
              } catch (e) {
                if (!mounted) return;
                _showAlertDialog("Hata", "Şifre güncelleme başarısız: ${e.toString()}");
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 90,
                backgroundImage: AssetImage('assets/ciftTeker.png'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Çift Teker',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignIn ? "Giriş Yap" : "Kayıt Ol",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    activeColor: Colors.orange,
                    value: isSignIn,
                    onChanged: (value) {
                      setState(() {
                        isSignIn = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Email", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'E-posta gerekli';
                          if (!_isValidEmail(value.trim())) return 'Geçerli bir e-posta girin';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text("Şifre", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Şifre gerekli';
                          if (!_isValidPassword(value)) {
                            return 'Şifre en az 5 karakter ve özel karakter içermeli';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      if (!isSignIn) ...[
                        const Text('İsim - Soyisim', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'İsim',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (!isSignIn) {
                                    if (value == null || value.trim().isEmpty) return 'İsim gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Soyisim',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (!isSignIn) {
                                    if (value == null || value.trim().isEmpty) return 'Soyisim gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text("Kullanıcı Adı", style: TextStyle(fontSize: 14)),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!isSignIn) {
                              if (value == null || value.trim().isEmpty) return 'Kullanıcı adı gerekli';
                              if (value.trim().length < 3) return 'En az 3 karakter girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text('Telefon Numarası', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (!isSignIn) {
                              if (value == null || value.trim().isEmpty) return 'Telefon numarası gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Kız', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isMale,
                                  activeColor: _isMale ? Colors.blue : Colors.pink,
                                  inactiveThumbColor: _isMale ? Colors.pink : Colors.blue,
                                  onChanged: (val) {
                                    setState(() {
                                      _isMale = val;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text('Erkek', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (isSignIn) {
                                _submitSignIn();
                              } else {
                                _submitSignUp();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 14),
                            ),
                            child: Text(
                              isSignIn ? "Sign In" : "Sign Up",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isSignIn)
                        GestureDetector(
                          onTap: () {
                            _showForgotPasswordDialog(); // güncellendi
                          },
                          child: const Center(
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
