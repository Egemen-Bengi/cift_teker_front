import 'dart:convert';
import 'package:cift_teker_front/models/requests/updatePassword_request.dart';
import 'package:http/http.dart' as http;
import '../models/requests/login_request.dart';
import '../models/responses/login_response.dart';

class LoginService {
  final String baseUrl =
      "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/auth";

  /// Login işlemi
  Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse("$baseUrl/login");

    print("Request Body: ${jsonEncode(request.toJson())}");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final loginData = LoginResponse.fromJson(body);

      if (loginData.token == null || loginData.token!.isEmpty) {
        throw Exception("Token boş, login başarısız");
      }

      return loginData;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
          "Login failed: ${response.statusCode} - ${response.body}");
    } else {
      throw Exception(
          "Login failed: ${response.statusCode} - ${response.body}");
    }
  }

  /// Şifre güncelleme
  Future<String> updatePassword(
      UpdatePasswordRequest request, String token) async {
    final url = Uri.parse("$baseUrl/updatePassword");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
          "Password update failed: ${response.statusCode} - ${response.body}");
    }
  }
}
