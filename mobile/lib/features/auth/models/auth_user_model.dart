class AuthUserModel {
  final String id;
  final String name;
  final String email;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}
