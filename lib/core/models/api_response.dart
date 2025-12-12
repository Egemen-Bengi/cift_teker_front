class ApiResponse<T> {
  final String message;
  final String? httpStatus;
  final T data;

  ApiResponse({
    required this.message,
    required this.data,
    this.httpStatus,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic object) fromJsonT,
  ) {
    return ApiResponse<T>(
      message: json['message'],
      httpStatus: json['httpStatus'],
      data: fromJsonT(json['object']),
    );
  }
}
