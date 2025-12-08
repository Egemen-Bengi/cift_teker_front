import 'package:dio/dio.dart';
import '../models/requests/rideHistory_request.dart';
import '../models/responses/rideHistory_response.dart';

class RideHistoryService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl:
          "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/ride-history",
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 5),
    ),
  );

  //  surus kaydi

  Future<RideHistoryResponse> saveRideHistory(
    RideHistoryRequest request,
    String token,
  ) async {
    try {
      final response = await _dio.post(
        "/save",
        data: request.toJson(),
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return RideHistoryResponse.fromJson(response.data["object"]);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // kullanici ride history kayitlari

  Future<List<RideHistoryResponse>> getMyRideHistory(String token) async {
    try {
      final response = await _dio.get(
        "/me",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final List<dynamic> dataList = response.data["object"];

      return dataList
          .map((json) => RideHistoryResponse.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // kayit silme

  Future<String> deleteMyRideHistory(int historyId, String token) async {
    try {
      final response = await _dio.delete(
        "/$historyId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data["message"];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  //bireysel sürüş başlatma
  Future<int> startRide(String token) async {
    try {
      final response = await _dio.post(
        "/start",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      // Backend ResponseMessage<Long> döndüğü için object alanını alıyoruz
      return response.data["object"] as int;
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
