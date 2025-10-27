import 'package:dio/dio.dart';
import '../models/user_request.dart';
import '../models/user_response.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8081/user"));

  Future<UserResponse> saveUser(UserRequest request) async {
    final response = await _dio.post(
      '/saveUser',
      data: request.toJson(),
    );

    return UserResponse.fromJson(response.data['object']);
  }
}