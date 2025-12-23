import 'package:cift_teker_front/core/models/api_response.dart';
import 'package:dio/dio.dart';
import '../models/requests/sharedRoute_request.dart';
import '../models/responses/sharedRoute_response.dart';

class SharedRouteService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/shared-routes",
    ),
  );

  // Yeni rota kaydetme
  Future<SharedRouteResponse> saveSharedRoute(
    SharedRouteRequest request,
    String token,
  ) async {
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

  // Rota silme
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

  // Kullanıcının rotalarını listeleme
  Future<ApiResponse<List<SharedRouteResponse>>> getSharedRoutes(
    String token,
  ) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List list = response.data["object"];
      final routes = list.map((e) => SharedRouteResponse.fromJson(e)).toList();
      return ApiResponse(data: routes, message: "Benim paylaştığım rotalar");
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Tüm rotaları listeleme
  Future<ApiResponse<List<SharedRouteResponse>>> getAllSharedRoutes(
    String token,
  ) async {
    final response = await _dio.get(
      "/all",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (object) =>
          (object as List).map((e) => SharedRouteResponse.fromJson(e)).toList(),
    );
  }

  Future<SharedRouteResponse> getSharedRouteById(
    int sharedRouteId,
    String token,
  ) async {
    final response = await _dio.get(
      "/$sharedRouteId",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return SharedRouteResponse.fromJson(response.data["object"]);
  }

  // Hata yönetimi
  Exception _handleError(DioException e) {
    if (e.response != null) {
      return Exception(
        "API Error: ${e.response?.statusCode} - ${e.response?.data}",
      );
    }
    return Exception("Bağlantı hatası: ${e.message}");
  }
}
