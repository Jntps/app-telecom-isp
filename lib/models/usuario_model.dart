class UsuarioModel {
  final int? id;
  final String email;
  final String? token;

  UsuarioModel({
    this.id,
    required this.email,
    this.token,
  });

  // Comunicação com a API REST
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      email: json['email'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
    };
  }

  // Persistência local SQLite
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'],
      email: map['email'] ?? '',
      token: map['token'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'token': token,
    };
  }
}