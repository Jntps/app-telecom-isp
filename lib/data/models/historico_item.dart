class HistoricoItem {
  final int? id;
  final int chamadoId;
  final String codigoCliente;
  final String nomeCliente;
  final String categoria;
  final String descricao;
  final String dataConclusao;
  final String? fotoPath;
  final String? fotoUrl;
  final bool sincronizado;

  const HistoricoItem({
    this.id,
    required this.chamadoId,
    required this.codigoCliente,
    required this.nomeCliente,
    required this.categoria,
    required this.descricao,
    required this.dataConclusao,
    this.fotoPath,
    this.fotoUrl,
    required this.sincronizado,
  });

  factory HistoricoItem.fromMap(Map<String, dynamic> map) => HistoricoItem(
        id: map['id'] as int?,
        chamadoId: map['chamadoId'] as int,
        codigoCliente: (map['codigoCliente'] ?? '').toString(),
        nomeCliente: (map['nomeCliente'] ?? '').toString(),
        categoria: (map['categoria'] ?? '').toString(),
        descricao: (map['descricao'] ?? '').toString(),
        dataConclusao: (map['dataConclusao'] ?? '').toString(),
        fotoPath: map['fotoPath']?.toString(),
        fotoUrl: map['fotoUrl']?.toString(),
        sincronizado: map['sincronizado'] == 1,
      );

  factory HistoricoItem.fromJson(Map<String, dynamic> json) {
    final dados = json['atendimento'] is Map
        ? json['atendimento'] as Map
        : <String, dynamic>{};
    return HistoricoItem(
      id: int.tryParse((dados['id'] ?? '').toString()),
      chamadoId: int.parse((json['chamado_id'] ?? json['id']).toString()),
      codigoCliente: (json['codigo_cliente'] ?? '').toString(),
      nomeCliente: (json['nome_cliente'] ?? '').toString(),
      categoria: (dados['categoria_tecnico'] ?? '').toString(),
      descricao: (dados['descricao_procedimento'] ?? '').toString(),
      dataConclusao: (dados['data_resolucao'] ?? '').toString(),
      fotoUrl: dados['foto_url']?.toString(),
      sincronizado: true,
    );
  }
}
