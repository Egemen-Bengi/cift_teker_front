import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:cift_teker_front/models/responses/comment_response.dart';
import 'package:dio/dio.dart';

class CommentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/comments",
    ),
  );

  // yorum kaydetme
  Future<ApiResponse<CommentResponse>> saveComment(
    Map<String, dynamic> commentRequest,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        "/saveComment",
        data: commentRequest,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return ApiResponse.fromJson(
        response.data,
        (json) => CommentResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw Exception("saveComment hatası: ${e.response?.data}");
    }
  }

  // yorum silme
  Future<ApiResponse<String>> deleteComment(int commentId, String token) async {
    try {
      final response = await _dio.delete(
        "/deleteComment/$commentId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return ApiResponse.fromJson(response.data, (json) => json as String);
    } on DioException catch (e) {
      throw Exception("deleteComment hatası: ${e.response?.data}");
    }
  }

  //getirme
  Future<ApiResponse<List<CommentResponse>>> getMyComments(String token) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List list = response.data["object"];
      final comments = list.map((e) => CommentResponse.fromJson(e)).toList();
      return ApiResponse(data: comments, message: "Benim yorumlarım");
    } on DioException catch (e) {
      throw Exception("getMyComments hatası: $e");
    }
  }
}
