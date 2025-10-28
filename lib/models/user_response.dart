class UserResponse {
  final int userId;
  final String username;
  final String name;
  final String surname;
  final String email;
  final String role;
  final String profile_image;
  final DateTime created_at;
  

  UserResponse({
    required this.userId,
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    required this.profile_image,
    required this.created_at,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: json['userId'],
      username: json['username'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      role: json['role'],
      profile_image: json['profile_image'],
      created_at: json['created_at'],
    );
  }
}
