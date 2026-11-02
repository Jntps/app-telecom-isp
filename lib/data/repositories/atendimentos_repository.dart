import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';
import '../models/atendimento_model.dart';
import '../models/historico_item.dart';
import 'auth_repository.dart';

class ResultadoSincronizacao {
  final int enviados;
  final int falhas;
  const ResultadoSincronizacao(this.enviados, this.falhas);
}

class AtendimentosRepository {
  final LocalDatasource local;
  final RemoteDatasource remoto;
  final AuthRepository autenticacao;

  AtendimentosRepository({
    LocalDatasource? local,
    RemoteDatasource? remoto,
    AuthRepository? autenticacao,
  })  : local = local ?? LocalDatasource(),
        remoto = remoto ?? RemoteDatasource(),
        autenticacao = autenticacao ?? AuthRepository();

  Future<int> concluir({
    required int chamadoId,
    required String categoria,
    required String descricao,
    String? fotoPath,
  }) {
    return local.concluirAtendimento(AtendimentoModel(
      chamadoId: chamadoId,
      categoria: categoria,
      descricao: descricao.trim(),
      dataConclusao: DateTime.now().toIso8601String(),
      fotoPath: fotoPath,
    ));
  }

  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    final token = await autenticacao.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Faça login para sincronizar.');
    }

    final pendentes = await local.listarPendentes();
    var enviados = 0;
    var falhas = 0;
    for (final atendimento in pendentes) {
      try {
        final url = await remoto.enviarAtendimento(token, atendimento);
        await local.marcarSincronizado(atendimento.id!, fotoUrl: url);
        enviados++;
      } catch (_) {
        // Conserva o registro como pendente para nova tentativa.
        falhas++;
      }
    }
    return ResultadoSincronizacao(enviados, falhas);
  }

  Future<List<HistoricoItem>> carregarHistorico() async {
    final salvos = await local.listarHistorico();
    final porChamado = <int, HistoricoItem>{
      for (final item in salvos) item.chamadoId: item,
    };
    try {
      final token = await autenticacao.getToken();
      if (token != null && token.isNotEmpty) {
        final naNuvem = await remoto.listarHistorico(token);
        for (final item in naNuvem) {
          final existente = porChamado[item.chamadoId];
          // Dados pendentes offline não podem ser sobrescritos pela nuvem.
          if (existente == null || existente.sincronizado) {
            porChamado[item.chamadoId] = item;
          }
        }
      }
    } catch (_) {
      // O histórico local permanece disponível no modo avião.
    }
    final resultado = porChamado.values.toList();
    resultado.sort((a, b) => b.dataConclusao.compareTo(a.dataConclusao));
    return resultado;
  }
}
