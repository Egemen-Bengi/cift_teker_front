import 'package:dio/dio.dart';
import '../models/responses/rating_response.dart';
import '../../core/models/api_response.dart';

class RatingService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/ratings"));

  // sharedRouteId ve ratingValue ile rating kaydetme
  Future<ApiResponse<RatingResponse>> saveRating(
      int sharedRouteId, double ratingValue, String token) async {
    try {
      final response = await _dio.post(
        '/saveRating/$sharedRouteId/$ratingValue',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => RatingResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //  silme
  Future<ApiResponse<String>> deleteRating(int ratingId, String token) async {
    try {
      final response = await _dio.delete(
        '/deleteRating/$ratingId',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => json as String,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(
          "API Error: ${e.response?.statusCode} - ${e.response?.data}");
    }
    return Exception("Bağlantı hatası: ${e.message}");
  }
}
