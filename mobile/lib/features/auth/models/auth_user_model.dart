class AuthUserModel {
  final String id;
  final String name;
  final String email;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
        id: json['id'].toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
      );
}
