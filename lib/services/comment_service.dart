import 'package:dio/dio.dart';

class CommentService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/comments",
      headers: {"Content-Type": "application/json"},
    ),
  );

  // tokeni parametre olarak alıyoruz
  CommentService(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
  }

  // yorum kaydetme 
  Future<Map<String, dynamic>> saveComment(Map<String, dynamic> commentRequest) async {
    try {
      final response = await _dio.post(
        "/saveComment",
        data: commentRequest,
      );
      return response.data;
    } catch (e) {
      throw Exception("saveComment hatası: $e");
    }
  }

  // yorum silme 
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final response = await _dio.delete("/deleteComment/$commentId");
      return response.data;
    } catch (e) {
      throw Exception("deleteComment hatası: $e");
    }
  }
}
