import 'package:dio/dio.dart';
import '../models/responses/like_response.dart';
import '../../core/models/api_response.dart';

class LikeService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/likes",
    ),
  );

  // like kaydetme
  Future<ApiResponse<LikeResponse?>> toggleLike(
    int sharedRouteId,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        '/toggle/$sharedRouteId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => json == null ? null : LikeResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // like sayısı
  Future<ApiResponse<int>> getLikeCount(int sharedRouteId) async {
    try {
      final response = await _dio.get("/count/$sharedRouteId");

      return ApiResponse.fromJson(response.data, (json) => json as int);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // kullanıcı beğenmiş mi
  Future<ApiResponse<bool>> isLiked(int sharedRouteId, String token) async {
    try {
      final response = await _dio.get(
        "/is-liked/$sharedRouteId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<List<LikeResponse>>> getMyLikes(String token) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('object')) {
        final List list = data['object'];
        final likes = list.map((e) => LikeResponse.fromJson(e)).toList();
        return ApiResponse(data: likes, message: "Benim beğenilerim");
      }
      return ApiResponse(data: [], message: response.data['message']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  
  Future<ApiResponse<List<LikeResponse>>> getLikesByRoute(
    int sharedRouteId,
    String token,
  ) async {
    try {
      final response = await _dio.get(
        '/route/$sharedRouteId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('object')) {
        final List list = data['object'];
        final likes = list.map((e) => LikeResponse.fromJson(e)).toList();
        return ApiResponse(data: likes, message: data['message']);
      }
      return ApiResponse(data: [], message: data['message']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(
        "API Error: ${e.response?.statusCode} - ${e.response?.data}",
      );
    }
    return Exception("Bağlantı hatası: ${e.message}");
  }
}
