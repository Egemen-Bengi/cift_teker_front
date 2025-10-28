class UserRequest {
  final String name;
  final String surname;
  final String username;
  final String email;
  final String phoneNumber;
  final String gender;
  final String password;

  UserRequest({
    required this.name,
    required this.surname,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'surname': surname,
    'username': username,
    'email': email,
    'password': password,
    'phoneNumber': phoneNumber,
    'gender': gender,
  };
}
