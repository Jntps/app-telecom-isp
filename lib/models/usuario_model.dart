class UsuarioModel {
  final int? id;
  final String email;
  final String nome;
  final String? token;

  const UsuarioModel({
    this.id,
    required this.email,
    this.nome = '',
    this.token,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final dados = json['dados'] is Map ? json['dados'] as Map : json;
    final usuario = dados['usuario'] is Map ? dados['usuario'] as Map : dados;
    return UsuarioModel(
      id: int.tryParse((usuario['id'] ?? '').toString()),
      email: (usuario['email'] ?? '').toString(),
      nome: (usuario['nome'] ?? '').toString(),
      token: dados['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'email': email, 'nome': nome, 'token': token};

  factory UsuarioModel.fromMap(Map<String, dynamic> map) => UsuarioModel(
        id: map['id'] as int?,
        email: (map['email'] ?? '').toString(),
        nome: (map['nome'] ?? '').toString(),
        token: map['token']?.toString(),
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'email': email, 'nome': nome, 'token': token};
}