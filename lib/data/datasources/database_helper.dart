import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _abrirBanco('telecom_isp.db');
    return _database!;
  }

  Future<Database> _abrirBanco(String nome) async {
    final caminho = join(await getDatabasesPath(), nome);
    return openDatabase(
      caminho,
      version: 2,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chamados (
            id INTEGER PRIMARY KEY,
            codigoCliente TEXT NOT NULL,
            nome TEXT NOT NULL,
            categoria TEXT NOT NULL,
            resumo TEXT NOT NULL,
            endereco TEXT NOT NULL,
            bairro TEXT NOT NULL DEFAULT '',
            cidade TEXT NOT NULL DEFAULT '',
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            status TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE atendimentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chamadoId INTEGER NOT NULL,
            categoria TEXT NOT NULL,
            descricao TEXT NOT NULL,
            dataConclusao TEXT NOT NULL,
            fotoPath TEXT,
            fotoUrl TEXT,
            sincronizado INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (chamadoId) REFERENCES chamados (id)
          )
        ''');
      },
      onUpgrade: (db, antiga, nova) async {
        if (antiga < 2) {
          await db.execute("ALTER TABLE chamados ADD COLUMN bairro TEXT NOT NULL DEFAULT ''");
          await db.execute("ALTER TABLE chamados ADD COLUMN cidade TEXT NOT NULL DEFAULT ''");
          await db.execute('ALTER TABLE atendimentos ADD COLUMN fotoUrl TEXT');
        }
      },
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    if (db != null && db.isOpen) await db.close();
  }
}
