class AtendimentoModel {
  final int? id;
  final int chamadoId;
  final String categoria;
  final String descricao;
  final String dataConclusao;
  final String? fotoPath;
  final int sincronizado;

  AtendimentoModel({
    this.id,
    required this.chamadoId,
    required this.categoria,
    required this.descricao,
    required this.dataConclusao,
    this.fotoPath,
    this.sincronizado = 0,
  });

  factory AtendimentoModel.fromJson(Map<String, dynamic> json) {
    return AtendimentoModel(
      id: json['id'],
      chamadoId: json['chamadoId'],
      categoria: json['categoria'] ?? '',
      descricao: json['descricao'] ?? '',
      dataConclusao: json['dataConclusao'] ?? '',
      sincronizado: 1, // Se veio da API, já está sincronizado
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chamadoId': chamadoId,
      'categoria': categoria,
      'descricao': descricao,
      'dataConclusao': dataConclusao,
    };
  }

  factory AtendimentoModel.fromMap(Map<String, dynamic> map) {
    return AtendimentoModel(
      id: map['id'],
      chamadoId: map['chamadoId'],
      categoria: map['categoria'],
      descricao: map['descricao'],
      dataConclusao: map['dataConclusao'],
      fotoPath: map['fotoPath'],
      sincronizado: map['sincronizado'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chamadoId': chamadoId,
      'categoria': categoria,
      'descricao': descricao,
      'dataConclusao': dataConclusao,
      'fotoPath': fotoPath,
      'sincronizado': sincronizado,
    };
  }
}