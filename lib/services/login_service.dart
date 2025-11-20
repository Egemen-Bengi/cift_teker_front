import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/requests/login_request.dart';
import '../models/responses/login_response.dart';
import '../models/requests/updatePassword_request.dart';
import '../../core/models/api_response.dart';

class LoginService {
  final String baseUrl = "http://localhost:8081/auth";

  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(response.body),LoginResponse.fromJson);
    } else {
      throw Exception("Login failed: ${response.statusCode}");
    }
  }
  // update password kismi eksikti eklendi
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
      throw Exception("Password update failed: ${response.statusCode}");
    }
  }
}
