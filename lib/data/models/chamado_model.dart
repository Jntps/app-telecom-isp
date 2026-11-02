class ChamadoModel {
  final int id;
  final String codigoCliente;
  final String nome;
  final String categoria;
  final String resumo;
  final String endereco;
  final String bairro;
  final String cidade;
  final double latitude;
  final double longitude;
  final String status;

  const ChamadoModel({
    required this.id,
    required this.codigoCliente,
    required this.nome,
    required this.categoria,
    required this.resumo,
    required this.endereco,
    this.bairro = '',
    this.cidade = '',
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  String get enderecoCompleto =>
      [endereco, bairro, cidade].where((parte) => parte.trim().isNotEmpty).join(', ');

  ChamadoModel copyWith({String? status}) => ChamadoModel(
        id: id,
        codigoCliente: codigoCliente,
        nome: nome,
        categoria: categoria,
        resumo: resumo,
        endereco: endereco,
        bairro: bairro,
        cidade: cidade,
        latitude: latitude,
        longitude: longitude,
        status: status ?? this.status,
      );

  factory ChamadoModel.fromJson(Map<String, dynamic> json) => ChamadoModel(
        id: _inteiro(json['id']),
        codigoCliente: (json['codigo_cliente'] ?? '').toString(),
        nome: (json['nome_cliente'] ?? '').toString(),
        categoria: (json['categoria_informada'] ?? '').toString(),
        resumo: (json['descricao_problema'] ?? '').toString(),
        endereco: (json['endereco_cliente'] ?? '').toString(),
        bairro: (json['bairro'] ?? '').toString(),
        cidade: (json['cidade'] ?? '').toString(),
        latitude: _decimal(json['latitude']),
        longitude: _decimal(json['longitude']),
        status: (json['status'] ?? 'ativo').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo_cliente': codigoCliente,
        'nome_cliente': nome,
        'categoria_informada': categoria,
        'descricao_problema': resumo,
        'endereco_cliente': endereco,
        'bairro': bairro,
        'cidade': cidade,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      };

  factory ChamadoModel.fromMap(Map<String, dynamic> map) => ChamadoModel(
        id: _inteiro(map['id']),
        codigoCliente: (map['codigoCliente'] ?? '').toString(),
        nome: (map['nome'] ?? '').toString(),
        categoria: (map['categoria'] ?? '').toString(),
        resumo: (map['resumo'] ?? '').toString(),
        endereco: (map['endereco'] ?? '').toString(),
        bairro: (map['bairro'] ?? '').toString(),
        cidade: (map['cidade'] ?? '').toString(),
        latitude: _decimal(map['latitude']),
        longitude: _decimal(map['longitude']),
        status: (map['status'] ?? 'ativo').toString(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'codigoCliente': codigoCliente,
        'nome': nome,
        'categoria': categoria,
        'resumo': resumo,
        'endereco': endereco,
        'bairro': bairro,
        'cidade': cidade,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      };

  static int _inteiro(dynamic valor) => int.parse(valor.toString());
  static double _decimal(dynamic valor) =>
      double.tryParse(valor?.toString() ?? '') ?? 0.0;
}
