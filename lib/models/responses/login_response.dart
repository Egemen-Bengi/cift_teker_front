class LoginResponse {
  final String? username;
  final String? role;
  final String? token;
  final String? name;

  LoginResponse({
    this.username,
    this.role,
    this.token,
    this.name,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      username: json['username'] as String?,
      role: json['role'] as String?,
      token: json['token'] as String?,
      name: json['name'] as String?,
    );
  }
}
