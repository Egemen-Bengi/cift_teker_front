import 'package:dio/dio.dart';
import '../models/requests/groupEvent_request.dart';
import '../models/responses/groupEvent_response.dart';
import '../../core/models/api_response.dart';
import '../models/requests/updateGroupEvent_request.dart';

class EventService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com",
    ),
  );

  // Yeni grup etkinliği oluşturma
  Future<ApiResponse<GroupEventResponse>> createGroupEvent(
    GroupEventRequest request,
    String token,
  ) async {
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
    String token,
  ) async {
    final response = await _dio.get(
      "/event/me",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (jsonList) => (jsonList as List)
          .map(
            (json) => GroupEventResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  // Tüm grup etkinliklerini listeleme
  Future<ApiResponse<List<GroupEventResponse>>> getAllGroupEvents(
    String token,
  ) async {
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

  // Grup etkinliği silme
  Future<void> deleteGroupEvent(int groupEventId, String token) async {
    await _dio.delete(
      "/event/group/delete/$groupEventId",
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );
  }

  // Grup etkinliği güncelleme
  Future<ApiResponse<GroupEventResponse>> updateGroupEvent(
    int groupEventId,
    UpdateGroupEventRequest request,
    String token,
  ) async {
    final response = await _dio.patch(
      "/event/group/update/$groupEventId",
      data: request.toJson(),
      options: Options(headers: {"Authorization": "Bearer $token"}),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => GroupEventResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
