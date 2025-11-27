import 'package:dio/dio.dart';
import '../models/requests/like_request.dart';
import '../models/responses/like_response.dart';
import '../../core/models/api_response.dart';

class LikeService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8081/likes"));

  Future<ApiResponse<LikeResponse>> saveLike(
      LikeRequest request, String token) async {
    final response = await _dio.post(
      '/saveLike',
      data: request.toJson(),
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => LikeResponse.fromJson(json),
    );
  }

  Future<ApiResponse<String>> deleteLike(int likeId, String token) async {
    final response = await _dio.delete(
      '/deleteLike/$likeId',
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => json as String,
    );
  }
}
