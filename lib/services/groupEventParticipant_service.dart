import 'package:dio/dio.dart';
import '../models/responses/groupEventParticipant_response.dart';

class GroupEventParticipantService {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/group-event-participants"),
  );

  // etkinliğe katılma
  Future<GroupEventParticipantResponse> joinEvent(
      int groupEventId, String token) async {
    try {
      final response = await _dio.post(
        "/join/$groupEventId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return GroupEventParticipantResponse.fromJson(response.data["object"]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // etkinlikten ayrılma
  Future<void> leaveEvent(int groupEventId, String token) async {
    try {
      await _dio.delete(
        "/leave/$groupEventId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // etkinlik katılımcılarını getirme
  Future<List<GroupEventParticipantResponse>> getParticipants(
      int groupEventId) async {
    try {
      final response = await _dio.get("/get/$groupEventId");

      List<dynamic> list = response.data["object"];
      
      return list
          .map((item) => GroupEventParticipantResponse.fromJson(item))
          .toList();
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
