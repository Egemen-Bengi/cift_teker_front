import 'package:dio/dio.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class LoginService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8081/auth"));

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/login', data: request.toJson());
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Login failed: ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}
