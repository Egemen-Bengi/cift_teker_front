class LoginResponse {
  final String username;
  final String role;
  final String token;
  final String name;
  LoginResponse({
    required this.username,
    required this.role,
    required this.token,
    required this.name,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      username: json['username'],
      role: json['role'],
      token: json['token'],
      name: json['name'],
    );
  }
}
