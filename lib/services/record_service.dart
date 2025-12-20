import 'package:dio/dio.dart';

import '../models/responses/record_response.dart';
import '../core/models/api_response.dart';

class RecordService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/records",
    ),
  );

  // toggle record
  Future<ApiResponse<RecordResponse?>> toggleRecord(
    int sharedRouteId,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        "/toggle/$sharedRouteId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(
        response.data,
        (json) => json == null ? null : RecordResponse.fromJson(json),
      );
    } on DioException catch (e) {
      throw Exception("toggleRecord hatası: ${e.response?.data}");
    }
  }

  // kayıtlı mı?
  Future<ApiResponse<bool>> isRecorded(int sharedRouteId, String token) async {
    try {
      final response = await _dio.get(
        "/is-recorded/$sharedRouteId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return ApiResponse.fromJson(response.data, (json) => json as bool);
    } on DioException catch (e) {
      throw Exception("isRecorded hatası: ${e.response?.data}");
    }
  }

  // benim kayıtlarım
  Future<ApiResponse<List<RecordResponse>>> getMyRecords(String token) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List list = response.data["object"];
      final records = list.map((e) => RecordResponse.fromJson(e)).toList();

      return ApiResponse(data: records, message: response.data["message"]);
    } on DioException catch (e) {
      throw Exception("getMyRecords hatası: ${e.response?.data}");
    }
  }
}
