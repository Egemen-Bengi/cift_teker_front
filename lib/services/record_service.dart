import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/responses/record_response.dart';
import '../core/models/api_response.dart';

class RecordService {
  final String baseUrl =
      "https://cift-teker-sosyal-bisiklet-uygulamasi.onrender.com/records";

  Future<ApiResponse<RecordResponse>> saveRecord(
      int sharedRouteId, String token) async {
    final url = Uri.parse("$baseUrl/saveRecord/$sharedRouteId");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(
        jsonDecode(response.body),
        (json) => RecordResponse.fromJson(json as Map<String, dynamic>),
      );
    } else {
      throw Exception(
          "Save record failed: ${response.statusCode} - ${response.body}");
    }
  }

  Future<ApiResponse<String>> deleteRecord(
      int recordId, String token) async {
    final url = Uri.parse("$baseUrl/deleteRecord/$recordId");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(
        jsonDecode(response.body),
            (data) => data.toString(),
      );
    } else {
      throw Exception(
          "Delete record failed: ${response.statusCode} - ${response.body}");
    }
  }
}
