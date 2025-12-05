import 'package:dio/dio.dart';
import '../models/requests/user_request.dart';
import '../models/requests/updateUsername_request.dart';
import '../models/responses/user_response.dart';
import '../../core/models/api_response.dart';

class UserService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/user",
    ),
  );

  // kayıt olma
  Future<ApiResponse<UserResponse>> saveUser(
    UserRequest request,
    String userRole,
  ) async {
    try {
      final response = await _dio.post(
        '/register/$userRole',
        data: request.toJson(),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'API Error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        throw Exception('Bağlantı hatası: ${e.message}');
      }
    }
  }

  // kullanıcı adı güncelleme
  Future<ApiResponse<UserResponse>> updateUsername(
    UpdateUsernameRequest request,
    String token,
  ) async {
    try {
      final response = await _dio.patch(
        '/updateUsername',
        data: request.toJson(),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          "API Error: ${e.response?.statusCode} - ${e.response?.data}",
        );
      } else {
        throw Exception("Bağlantı hatası: ${e.message}");
      }
    }
  }

  // profil resmi güncelleme
  Future<ApiResponse<UserResponse>> updateProfileImage(
    String newProfileImage,
    String token,
  ) async {
    try {
      final response = await _dio.patch(
        '/updateProfileImage',
        data: {"newProfileImage": newProfileImage},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          "API Error: ${e.response?.statusCode} - ${e.response?.data}",
        );
      } else {
        throw Exception("Bağlantı hatası: ${e.message}");
      }
    }
  }

  // giriş yapmış kullanıcının bilgilerini getirme
  Future<ApiResponse<UserResponse>> getMyInfo(String token) async {
    try {
      final response = await _dio.get(
        '/me',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => UserResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          "API Error: ${e.response?.statusCode} - ${e.response?.data}",
        );
      } else {
        throw Exception("Bağlantı hatası: ${e.message}");
      }
    }
  }
}
