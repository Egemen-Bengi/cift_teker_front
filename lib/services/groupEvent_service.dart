import 'package:dio/dio.dart';
import '../models/requests/groupEvent_request.dart';
import '../models/responses/groupEvent_response.dart';
import '../../core/models/api_response.dart';

class EventService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com",
    ),
  );

  // Yeni grup etkinliği oluşturma
  Future<ApiResponse<GroupEventResponse>> createGroupEvent(
      GroupEventRequest request, String token) async {
    final response = await _dio.post(
      "/event/group",
      data: request.toJson(),
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => GroupEventResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  // Giriş yapmış kullanıcının grup etkinliklerini listeleme
  Future<ApiResponse<List<GroupEventResponse>>> getMyGroupEvents(
      String token) async {
    final response = await _dio.get(
      "/event/me",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (jsonList) => (jsonList as List)
          .map((json) => GroupEventResponse.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<List<GroupEventResponse>>> getAllGroupEvents(
      String token) async {
    final response = await _dio.get(
      "/event/all",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (jsonList) => (jsonList as List)
          .map((e) => GroupEventResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> deleteGroupEvent(int groupEventId, String token) async {
    await _dio.delete(
      "/event/group/$groupEventId",
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );
  }
}