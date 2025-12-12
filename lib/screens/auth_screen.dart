// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, avoid_print, curly_braces_in_flow_control_structures, unnecessary_brace_in_string_interps, unused_local_variable

import 'package:cift_teker_front/models/requests/login_request.dart';
import 'package:cift_teker_front/models/requests/updatePassword_request.dart';
import 'package:cift_teker_front/services/login_service.dart';
import 'package:cift_teker_front/models/requests/user_request.dart';
import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:cift_teker_front/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

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
  final TextEditingController _usernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  bool _isMale = true;

  String _genderText() {
    return _isMale ? "MALE" : "FEMALE";
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidUsername(String username) {
    final regex = RegExp(r'^[A-Za-z0-9_]{4,15}$');
    return regex.hasMatch(username);
  }

  bool _isValidPassword(String password) {
    final passwordRegex = RegExp(r'^.{5,}$');
    return passwordRegex.hasMatch(password);
  }

  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+90 (###) ### ## ##',
    filter: { "#": RegExp(r'[0-9]') },
  );

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
    if (!_formKey.currentState!.validate()) {
      _showAlertDialog(
        "Eksik veya Hatalı Bilgi",
        "Lütfen tüm alanları doğru şekilde doldurun.",
      );
      return;
    }

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userService = UserService();
      final rawPhone = phoneMaskFormatter.getUnmaskedText();

      final request = UserRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _firstNameController.text.trim(),
        surname: _lastNameController.text.trim(),
        phoneNumber: rawPhone,
        gender: _genderText(),
      );

      final response = await userService.saveUser(request, "USER");

      if (!mounted) return;
      Navigator.pop(context); // Loading dialog kapat

      if (response.message == "Register successful") {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Kayıt Başarılı",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text("Lütfen giriş yapın."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      isSignIn = true;
                    });
                  },
                  child: const Text("Tamam"),
                ),
              ],
            );
          },
        );
      } else {
        if (!mounted) return;
        _showAlertDialog("Hata", "Kayıt başarısız oldu");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Loading dialog kapat

      _showAlertDialog("Hata", "Kayıt olurken istenmeyen bir hata oluştu");
    }
  }

  // Giriş işlemini LoginService ile yapan fonksiyon
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  void _submitSignIn() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showAlertDialog("Hata", "Kullanıcı adı alanı boş olamaz.");
      return;
    }
    if (!_isValidUsername(username)) {
      _showAlertDialog("Hata", "Geçerli bir kullanıcı adı girin.");
      return;
    }
    if (password.isEmpty) {
      _showAlertDialog("Hata", "Şifre alanı boş olamaz.");
      return;
    }
    if (!_isValidPassword(password)) {
      _showAlertDialog("Hata", "Şifre en az 5 karakter olmalı.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final loginService = LoginService();
      final resp = await loginService.login(
        LoginRequest(username: username, password: password),
      );

      if (!mounted) return;
      Navigator.pop(context);

      final token = resp.token;
      if (token != null && token.isNotEmpty) {
        await storage.write(key: "auth_token", value: token);
      } else {
        throw Exception("Token boş, login başarısız");
      }

      final userName = resp.username ?? "Kullanıcı";

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // loading kapat

      _showAlertDialog("Hata", "Giriş yapılırken bir hata oluştu");
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
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre (Tekrar)",
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
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
                _showAlertDialog(
                  "Hata",
                  "Şifre en az 5 karakter olmalı.",
                );
                return;
              }

              try {
                final loginService = LoginService();
                final req = UpdatePasswordRequest(
                  oldPassword: oldPass,
                  newPassword: newPass,
                );
                await loginService.updatePassword(req, token);

                if (!mounted) return;
                Navigator.pop(context);
                _showAlertDialog(
                  "Başarılı",
                  "Şifreniz başarıyla güncellendi.",
                );
              } catch (e) {
                if (!mounted) return;
                _showAlertDialog(
                  "Hata",
                  "Şifre güncelleme başarısız",
                );
              }
            },
            child: const Text("Güncelle"),
          ),
        ],
      ),
    );
  }

  // Focus ve rule state ekleyin
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _uMin = false;
  bool _uMax = false;
  bool _uChars = false;
  bool _eValid = false;
  bool _pMin = false;

  void _validateUsername(String v) {
    final s = v.trim();
    _uMin = s.length >= 4;
    _uMax = s.length <= 15;
    _uChars = RegExp(r'^[A-Za-z0-9_]+$').hasMatch(s);
  }

  Widget _criteriaRow(String text, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
             color: ok ? Colors.green : Colors.grey, size: 18),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: ok ? Colors.green : Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _usernameCriteria() {
    if (_usernameController.text.isEmpty && !_usernameFocus.hasFocus) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _criteriaRow('En az 4 karakter', _uMin),
        _criteriaRow('En fazla 15 karakter', _uMax),
        _criteriaRow('Sadece harf, rakam ve _', _uChars),
      ],
    );
  }

  Widget _emailCriteria() {
    if (_emailController.text.isEmpty && !_emailFocus.hasFocus) return const SizedBox.shrink();
    return _criteriaRow('Geçerli e-mail formatı', _eValid);
  }

  Widget _passwordCriteria() {
    if (_passwordController.text.isEmpty && !_passwordFocus.hasFocus) return const SizedBox.shrink();
    return _criteriaRow('En az 5 karakter', _pMin);
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        onChanged: (val) { setState(() { _validateUsername(val); }); },
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı gerekli';
                          }
                          final username = value.trim();
                          if (username.length < 4 || username.length > 15) {
                            return 'Kullanıcı adı 4-15 karakter arasında olmalıdır';
                          }
                          if (!_isValidUsername(username)) {
                            return 'Sadece harf, rakam ve alt tire (_) kullanabilirsiniz';
                          }
                          return null;
                        },
                      ),
                      _usernameCriteria(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        onChanged: (val) {
                          setState(() {
                            _pMin = val.length >= 5;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                            return 'Şifre en az 5 karakter olmalı';
                          }
                          return null;
                        },
                      ),
                      _passwordCriteria(),
                      const SizedBox(height: 16),
                      if (!isSignIn) ...[
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
                                    if (value == null || value.trim().isEmpty)
                                      return 'İsim gerekli';
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
                                    if (value == null || value.trim().isEmpty)
                                      return 'Soyisim gerekli';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          onChanged: (val) {
                            setState(() {
                              _eValid = _isValidEmail(val.trim());
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'E-Mail',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!isSignIn) {
                              if (value == null || value.trim().isEmpty) {
                                return 'E-mail gerekli';
                              }
                              final email = value.trim();
                              if (!_isValidEmail(email)) {
                                return 'Geçerli bir e-mail adresi girin';
                              }
                            }
                            return null;
                          },
                        ),
                        _emailCriteria(),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [phoneMaskFormatter],
                          validator: (value) {
                            if (!isSignIn) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Telefon numarası gerekli';
                              }
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
                                const Text(
                                  'Kız',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isMale,
                                  activeColor: _isMale
                                      ? Colors.blue
                                      : Colors.pink,
                                  inactiveThumbColor: _isMale
                                      ? Colors.pink
                                      : Colors.blue,
                                  onChanged: (val) {
                                    setState(() {
                                      _isMale = val;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Erkek',
                                  style: TextStyle(fontSize: 14),
                                ),
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
                                horizontal: 40,
                                vertical: 14,
                              ),
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
