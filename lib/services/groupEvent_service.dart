import 'package:dio/dio.dart';
import '../models/requests/groupEvent_request.dart';
import '../models/responses/groupEvent_response.dart';
import '../../core/models/api_response.dart';

class EventService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "http://localhost:8081"));

  Future<ApiResponse<GroupEventResponse>> createGroupEvent(
      GroupEventRequest request, String token) async {

    final response = await _dio.post(
      "/event/group",
      data: request.toJson(),
      options: Options(
        headers: {"Authorization": "Bearer $token"},
      ),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => GroupEventResponse.fromJson(json),
    );
  }
}