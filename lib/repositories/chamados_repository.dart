import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';
import '../models/chamado_model.dart';
import 'auth_repository.dart';

class ChamadosRepository {
  final LocalDatasource local;
  final RemoteDatasource remoto;
  final AuthRepository autenticacao;

  ChamadosRepository({
    LocalDatasource? local,
    RemoteDatasource? remoto,
    AuthRepository? autenticacao,
  })  : local = local ?? LocalDatasource(),
        remoto = remoto ?? RemoteDatasource(),
        autenticacao = autenticacao ?? AuthRepository();

  Future<List<ChamadoModel>> listarLocais() => local.listarAbertos();

  Future<List<ChamadoModel>> atualizarDaApi() async {
    final token = await autenticacao.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Faça login para carregar os chamados.');
    }
    final chamados = await remoto.listarChamados(token);
    await local.salvarChamados(chamados);
    return local.listarAbertos();
  }
}