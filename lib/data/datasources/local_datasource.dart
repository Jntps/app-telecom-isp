import 'package:sqflite/sqflite.dart';

import '../models/atendimento_model.dart';
import '../models/chamado_model.dart';
import '../models/historico_item.dart';
import 'database_helper.dart';

class LocalDatasource {
  final DatabaseHelper helper;
  LocalDatasource({DatabaseHelper? helper})
      : helper = helper ?? DatabaseHelper.instance;

  Future<List<ChamadoModel>> listarAbertos({
    int limite = 100,
    int pagina = 0,
  }) async {
    final db = await helper.database;
    final registros = await db.query(
      'chamados',
      where: "status IN ('ativo', 'aberto')",
      orderBy: 'id ASC',
      limit: limite,
      offset: pagina * limite,
    );
    return registros.map(ChamadoModel.fromMap).toList();
  }

  Future<void> salvarChamados(List<ChamadoModel> chamados) async {
    final db = await helper.database;
    await db.transaction((txn) async {
      for (final chamado in chamados) {
        final existente = await txn.query(
          'chamados',
          columns: ['status'],
          where: 'id = ?',
          whereArgs: [chamado.id],
          limit: 1,
        );
        // Uma sincronização não pode reabrir uma OS concluída offline.
        if (existente.isNotEmpty &&
            (existente.first['status'] == 'atendido' ||
                existente.first['status'] == 'resolvido')) {
          continue;
        }
        await txn.insert(
          'chamados',
          chamado.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<int> concluirAtendimento(AtendimentoModel atendimento) async {
    final db = await helper.database;
    return db.transaction<int>((txn) async {
      final rows = await txn.query(
        'chamados',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [atendimento.chamadoId],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Chamado não encontrado no SQLite.');
      if (rows.first['status'] != 'ativo' &&
          rows.first['status'] != 'aberto') {
        throw StateError('Esse chamado já foi finalizado.');
      }

      final id = await txn.insert(
        'atendimentos',
        atendimento.toMap()..remove('id'),
      );
      await txn.update(
        'chamados',
        {'status': 'atendido'},
        where: 'id = ?',
        whereArgs: [atendimento.chamadoId],
      );
      return id;
    });
  }

  Future<List<AtendimentoModel>> listarPendentes() async {
    final db = await helper.database;
    final rows = await db.query(
      'atendimentos',
      where: 'sincronizado = 0',
      orderBy: 'id ASC',
    );
    return rows.map(AtendimentoModel.fromMap).toList();
  }

  Future<void> marcarSincronizado(int id, {String? fotoUrl}) async {
    final db = await helper.database;
    final campos = <String, Object?>{'sincronizado': 1};
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      campos['fotoUrl'] = fotoUrl;
    }
    await db.update(
      'atendimentos',
      campos,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<HistoricoItem>> listarHistorico() async {
    final db = await helper.database;
    final rows = await db.rawQuery('''
      SELECT a.id, a.chamadoId, a.categoria, a.descricao,
             a.dataConclusao, a.fotoPath, a.fotoUrl, a.sincronizado,
             c.codigoCliente, c.nome AS nomeCliente
      FROM atendimentos a
      INNER JOIN chamados c ON c.id = a.chamadoId
      ORDER BY a.dataConclusao DESC, a.id DESC
    ''');
    return rows.map(HistoricoItem.fromMap).toList();
  }
}
