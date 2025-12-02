import 'package:dio/dio.dart';
import '../models/requests/sharedRoute_request.dart';
import '../models/responses/sharedRoute_response.dart';

class SharedRouteService {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/shared-routes"),
  );

  // Kaydetme
  Future<SharedRouteResponse> saveSharedRoute(
      SharedRouteRequest request, String token) async {
    try {
      final response = await _dio.post(
        "/saveRoute",
        data: request.toJson(),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return SharedRouteResponse.fromJson(response.data["object"]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Silme
  Future<String> deleteSharedRoute(int sharedRouteId, String token) async {
    try {
      final response = await _dio.delete(
        "/deleteRoute/$sharedRouteId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return response.data["message"];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Kendi rotalarını listeleme (private)
  Future<List<SharedRouteResponse>> getSharedRoutes(String token) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List<dynamic> objectList = response.data["object"];
      return objectList
          .map((e) => SharedRouteResponse.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Tüm rotaları listeleme (public)
  Future<List<SharedRouteResponse>> getAllSharedRoutes() async {
    try {
      final response = await _dio.get("/all");

      final List<dynamic> objectList = response.data["object"];
      return objectList
          .map((e) => SharedRouteResponse.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Hata yakalama
  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(
        "API Error: ${e.response?.statusCode} - ${e.response?.data}",
      );
    }
    return Exception("Bağlantı hatası: ${e.message}");
  }
}
