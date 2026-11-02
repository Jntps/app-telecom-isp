import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';
import 'package:projeto_telecom/services/location_service.dart';

void main() {
  test('campos snake_case da API são convertidos para o modelo', () {
    final chamado = ChamadoModel.fromJson({
      'id': 7,
      'codigo_cliente': 'CLI-7',
      'nome_cliente': 'Cliente Exemplo',
      'categoria_informada': 'Fibra',
      'descricao_problema': 'Sem sinal',
      'endereco_cliente': 'Rua A, 10',
      'bairro': 'Centro',
      'cidade': 'Gaspar',
      'latitude': -26.93,
      'longitude': -48.95,
      'status': 'ativo',
    });
    expect(chamado.codigoCliente, 'CLI-7');
    expect(chamado.nome, 'Cliente Exemplo');
    expect(chamado.enderecoCompleto, contains('Gaspar'));
    expect(ChamadoModel.fromMap(chamado.toMap()).id, 7);
  });

  test('Haversine retorna zero para coordenadas iguais', () {
    const ponto = Coordenada(-27.0, -48.0);
    expect(LocationService.distanciaKm(ponto, ponto), closeTo(0, 0.001));
  });

  test('Haversine retorna distância positiva', () {
    const pontoA = Coordenada(-27.0, -48.0);
    const pontoB = Coordenada(-27.1, -48.0);
    expect(LocationService.distanciaKm(pontoA, pontoB), greaterThan(10));
  });
}
