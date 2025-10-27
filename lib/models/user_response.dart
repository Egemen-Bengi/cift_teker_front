class UserResponse {
  final int userId;
  final String username;
  final String name;
  final String surname;
  final String email;
  

  UserResponse({
    required this.userId,
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: json['userId'],
      username: json['username'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
    );
  }
}
