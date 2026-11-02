class AtendimentoModel {
  final int? id;
  final int chamadoId;
  final String categoria;
  final String descricao;
  final String dataConclusao;
  final String? fotoPath;
  final String? fotoUrl;
  final int sincronizado;

  const AtendimentoModel({
    this.id,
    required this.chamadoId,
    required this.categoria,
    required this.descricao,
    required this.dataConclusao,
    this.fotoPath,
    this.fotoUrl,
    this.sincronizado = 0,
  });

  factory AtendimentoModel.fromJson(Map<String, dynamic> json) =>
      AtendimentoModel(
        id: int.tryParse((json['atendimento_id'] ?? json['id']).toString()),
        chamadoId: int.parse((json['chamado_id'] ?? json['chamadoId']).toString()),
        categoria: (json['categoria_tecnico'] ?? '').toString(),
        descricao: (json['descricao_procedimento'] ?? '').toString(),
        dataConclusao: (json['data_resolucao'] ?? '').toString(),
        fotoUrl: json['foto_url']?.toString(),
        sincronizado: 1,
      );

  Map<String, dynamic> toJson() => {
        'chamado_id': chamadoId,
        'categoria_tecnico': categoria,
        'descricao_procedimento': descricao,
        'data_resolucao': dataConclusao,
      };

  factory AtendimentoModel.fromMap(Map<String, dynamic> map) =>
      AtendimentoModel(
        id: map['id'] as int?,
        chamadoId: map['chamadoId'] as int,
        categoria: map['categoria'] as String,
        descricao: map['descricao'] as String,
        dataConclusao: map['dataConclusao'] as String,
        fotoPath: map['fotoPath'] as String?,
        fotoUrl: map['fotoUrl'] as String?,
        sincronizado: map['sincronizado'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chamadoId': chamadoId,
        'categoria': categoria,
        'descricao': descricao,
        'dataConclusao': dataConclusao,
        'fotoPath': fotoPath,
        'fotoUrl': fotoUrl,
        'sincronizado': sincronizado,
      };
}