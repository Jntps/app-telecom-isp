import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:projeto_telecom/data/datasources/database_helper.dart';
import 'package:projeto_telecom/data/datasources/local_datasource.dart';
import 'package:projeto_telecom/data/models/atendimento_model.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper.instance;
  final local = LocalDatasource(helper: helper);

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final caminho = join(await getDatabasesPath(), 'telecom_isp.db');
    await deleteDatabase(caminho);
  });

  tearDownAll(() async {
    await helper.close();
    final caminho = join(await getDatabasesPath(), 'telecom_isp.db');
    await deleteDatabase(caminho);
  });

  test('salva chamado e conclui atendimento totalmente offline', () async {
    await local.salvarChamados([
      const ChamadoModel(
        id: 10001,
        codigoCliente: 'CLI-TESTE',
        nome: 'Cliente Teste',
        categoria: 'Fibra',
        resumo: 'Sem conexão',
        endereco: 'Rua A',
        latitude: -27.0,
        longitude: -48.0,
        status: 'ativo',
      )
    ]);

    expect(await local.listarAbertos(), hasLength(1));

    final id = await local.concluirAtendimento(
      const AtendimentoModel(
        chamadoId: 10001,
        categoria: 'Conector',
        descricao: 'Conector substituído e testado',
        dataConclusao: '2026-10-31 10:00:00',
      ),
    );
    expect(id, greaterThan(0));
    expect(await local.listarAbertos(), isEmpty);

    final pendentes = await local.listarPendentes();
    expect(pendentes, hasLength(1));
    expect(pendentes.first.sincronizado, 0);

    await local.marcarSincronizado(id, fotoUrl: 'https://exemplo.com/foto.jpg');
    expect(await local.listarPendentes(), isEmpty);
    expect((await local.listarHistorico()).single.sincronizado, isTrue);
  });
}
