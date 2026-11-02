import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_telecom/data/datasources/local_datasource.dart';
import 'package:projeto_telecom/data/datasources/remote_datasource.dart';
import 'package:projeto_telecom/data/models/atendimento_model.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';
import 'package:projeto_telecom/data/models/historico_item.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';
import 'package:projeto_telecom/data/repositories/atendimentos_repository.dart';
import 'package:projeto_telecom/data/repositories/chamados_repository.dart';

class LocalFake extends LocalDatasource {
  List<ChamadoModel> chamados = [];
  List<AtendimentoModel> pendentes = [];
  final enviados = <int>[];

  @override
  Future<List<ChamadoModel>> listarAbertos({int limite = 100, int pagina = 0}) async =>
      chamados;

  @override
  Future<void> salvarChamados(List<ChamadoModel> novos) async {
    chamados = novos;
  }

  @override
  Future<List<AtendimentoModel>> listarPendentes() async => pendentes;

  @override
  Future<void> marcarSincronizado(int id, {String? fotoUrl}) async {
    enviados.add(id);
  }

  @override
  Future<List<HistoricoItem>> listarHistorico() async => [];
}

class RemotoFake extends RemoteDatasource {
  @override
  Future<List<ChamadoModel>> listarChamados(String token) async => [
        const ChamadoModel(
          id: 1, codigoCliente: 'CLI-1', nome: 'Cliente',
          categoria: 'Fibra', resumo: 'Sem conexão', endereco: 'Rua',
          latitude: -27.0, longitude: -48.0, status: 'ativo',
        ),
      ];

  @override
  Future<String?> enviarAtendimento(String token, AtendimentoModel atendimento) async =>
      'https://exemplo.com/foto.jpg';
}

class AutenticacaoFake extends AuthRepository {
  @override
  Future<String?> getToken() async => 'token-teste';
}

void main() {
  test('repositório de chamados grava resposta remota no datasource local', () async {
    final local = LocalFake();
    final repositorio = ChamadosRepository(
      local: local, remoto: RemotoFake(), autenticacao: AutenticacaoFake(),
    );
    final lista = await repositorio.atualizarDaApi();
    expect(lista.single.codigoCliente, 'CLI-1');
    expect(local.chamados, hasLength(1));
  });

  test('repositório sincroniza pendentes e confirma o envio', () async {
    final local = LocalFake();
    local.pendentes = [
      const AtendimentoModel(
        id: 5, chamadoId: 1, categoria: 'Fibra',
        descricao: 'Fibra corrigida', dataConclusao: '2026-10-31',
      )
    ];
    final repositorio = AtendimentosRepository(
      local: local, remoto: RemotoFake(), autenticacao: AutenticacaoFake(),
    );
    final resultado = await repositorio.sincronizarPendentes();
    expect(resultado.enviados, 1);
    expect(resultado.falhas, 0);
    expect(local.enviados, contains(5));
  });
}
