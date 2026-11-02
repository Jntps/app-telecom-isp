import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projeto_telecom/data/datasources/remote_datasource.dart';

void main() {
  test('login envia senha_hmac e lê token em dados', () async {
    final cliente = MockClient((requisicao) async {
      expect(requisicao.url.path, '/api/login');
      final corpo = jsonDecode(requisicao.body) as Map<String, dynamic>;
      expect(corpo['senha_hmac'], 'hash-de-teste');
      expect(corpo.containsKey('senha'), isFalse);
      return http.Response(
        jsonEncode({
          'sucesso': true,
          'dados': {'token': 'token-validacao', 'usuario': {'id': 5}}
        }),
        200,
      );
    });

    final resultado =
        await RemoteDatasource(client: cliente).login('teste@exemplo.com', 'hash-de-teste');
    expect(resultado.token, 'token-validacao');
    expect(resultado.usuarioId, 5);
  });

  test('GET /chamados converte lista em dados', () async {
    final cliente = MockClient((requisicao) async {
      expect(requisicao.headers['Authorization'], 'Bearer token-demo');
      return http.Response(
        jsonEncode({
          'sucesso': true,
          'dados': [
            {
              'id': 3,
              'codigo_cliente': 'CLI-3',
              'nome_cliente': 'Cliente',
              'categoria_informada': 'Rede',
              'descricao_problema': 'Falha',
              'endereco_cliente': 'Rua B',
              'bairro': 'Centro',
              'cidade': 'Gaspar',
              'latitude': -27.0,
              'longitude': -48.0,
              'status': 'ativo',
            }
          ]
        }),
        200,
      );
    });
    final chamados =
        await RemoteDatasource(client: cliente).listarChamados('token-demo');
    expect(chamados, hasLength(1));
    expect(chamados.single.codigoCliente, 'CLI-3');
  });
}
