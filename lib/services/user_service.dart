import 'package:dio/dio.dart';
import '../models/user_request.dart';
import '../models/user_response.dart';

class UserService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8081/user"));

  Future<UserResponse> saveUser(UserRequest request, String userRole) async {
    try {
      // kullanici rolu
      final response = await _dio.post(
        '/register/$userRole',
        data: request.toJson(),
      );

      // backendden donen response'un islenmesi
      return UserResponse.fromJson(response.data['object']);
    } on DioException catch (e) {
      // hata durumu
      if (e.response != null) {
        throw Exception(
            'API Error: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Bağlantı hatası: ${e.message}');
      }
    }
  }
}
