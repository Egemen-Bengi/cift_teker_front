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
  Future<ApiResponse<LikeResponse>> saveLike(
    int sharedRouteId,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        '/saveLike/$sharedRouteId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => LikeResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // silme
  Future<ApiResponse<String>> deleteLike(int likeId, String token) async {
    try {
      final response = await _dio.delete(
        '/deleteLike/$likeId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(response.data, (json) => json as String);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //getirme
  Future<ApiResponse<List<LikeResponse>>> getMyLikes(String token) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List list = response.data["object"];
      final likes = list.map((e) => LikeResponse.fromJson(e)).toList();
      return ApiResponse(data: likes, message: "Benim beğenilerim");
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
