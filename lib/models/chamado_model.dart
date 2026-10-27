class ChamadoModel {
  final int id;
  final String codigoCliente;
  final String nome;
  final String categoria;
  final String resumo;
  final String endereco;
  final double latitude;
  final double longitude;
  final String status;

  ChamadoModel({
    required this.id,
    required this.codigoCliente,
    required this.nome,
    required this.categoria,
    required this.resumo,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory ChamadoModel.fromJson(Map<String, dynamic> json) {
    return ChamadoModel(
      id: json['id'],
      codigoCliente: json['codigoCliente'] ?? '',
      nome: json['nome'] ?? '',
      categoria: json['categoria'] ?? '',
      resumo: json['resumoProblema'] ?? '',
      endereco: json['enderecoCompleto'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      status: json['status'] ?? 'aberto',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigoCliente': codigoCliente,
      'nome': nome,
      'categoria': categoria,
      'resumoProblema': resumo,
      'enderecoCompleto': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory ChamadoModel.fromMap(Map<String, dynamic> map) {
    return ChamadoModel(
      id: map['id'],
      codigoCliente: map['codigoCliente'],
      nome: map['nome'],
      categoria: map['categoria'],
      resumo: map['resumo'],
      endereco: map['endereco'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoCliente': codigoCliente,
      'nome': nome,
      'categoria': categoria,
      'resumo': resumo,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}