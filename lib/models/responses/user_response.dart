class UserResponse {
  final int userId;
  final String username;
  final String name;
  final String surname;
  final String email;
  final String role;
  final String? profileImage; 
  final DateTime createdAt;  

  UserResponse({
    required this.userId,
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.role,
    required this.profileImage,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: json['userId'],
      username: json['username'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      role: json['role'],
      profileImage: json['profileImage'], 
      createdAt: DateTime.parse(json['createdAt']), 
    );
  }
}