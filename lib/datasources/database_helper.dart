import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Padrão Singleton para garantir uma única instância da base de dados
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('telecom_isp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Tabela de Chamados (dados vindos da API)
    await db.execute('''
      CREATE TABLE chamados (
        id INTEGER PRIMARY KEY,
        codigoCliente TEXT NOT NULL,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        resumo TEXT NOT NULL,
        endereco TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Tabela de Atendimentos (criados localmente e pendentes de envio)
    await db.execute('''
      CREATE TABLE atendimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chamadoId INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        descricao TEXT NOT NULL,
        dataConclusao TEXT NOT NULL,
        fotoPath TEXT,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (chamadoId) REFERENCES chamados (id) ON DELETE CASCADE
      )
    ''');
  }

  // Métodos utilitários de fecho (opcional, mas recomendado)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}