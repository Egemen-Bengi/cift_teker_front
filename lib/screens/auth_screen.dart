import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isSignIn = true; // true -> Giriş, false -> Kayıt

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    final passwordRegex =
        RegExp(r'^(?=.*[!@#\$%^&*(),.?":{}|<>]).{5,}$'); // en az 5 ve özel karakter
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // VERİ TABANINA KAYIT İŞLEMİ BURADA YAPILACAK 
      // kullanıcı anasayfaya yönlendirilecek
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı!")),
      );
    } else {
      _showAlertDialog(
        "Eksik veya Hatalı Bilgi",
        "Lütfen tüm alanları doğru şekilde doldurun.",
      );
    }
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
              // Switch Butonu
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

              // Kart
              Container(
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
                        if (value!.isEmpty) return 'E-posta gerekli';
                        if (!_isValidEmail(value)) {
                          return 'Geçerli bir e-posta girin';
                        }
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
                        if (value!.isEmpty) return 'Şifre gerekli';
                        if (!_isValidPassword(value)) {
                          return 'Şifre en az 5 karakter ve özel karakter içermeli';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    if (!isSignIn) ...[
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // İsim ve Soyisim
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
                                    validator: (value) =>
                                        value!.isEmpty ? 'İsim gerekli' : null,
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
                                    validator: (value) =>
                                        value!.isEmpty ? 'Soyisim gerekli' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Telefon numarası
                            const Text('Telefon Numarası', style: TextStyle(fontSize: 14)),
                            const SizedBox(height: 4,),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon Numarası',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                                  value!.isEmpty ? 'Telefon numarası gerekli' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (isSignIn) {
                              // Giriş işlemi (henüz implement edilmedi)
                            } else {
                              _submitForm();
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
                          // Şifre sıfırlama ekranı
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
            ],
          ),
        ),
      ),
    );
  }
}