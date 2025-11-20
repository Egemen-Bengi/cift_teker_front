class ApiResponse<T> {
  final String message;
  final T data;

  ApiResponse({required this.message, required this.data});

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse(
      message: json['message'],
      data: fromJsonT(json['object']),
    );
  }
}
