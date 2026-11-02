# Código completo para copiar e colar

Cada seção indica **o nome e o caminho exatos** do arquivo.

Antes de copiar, renomeie a pasta `lib` antiga para `lib_backup` e crie a nova `lib` com os arquivos abaixo.

O arquivo binário `assets/images/logo.png` está no ZIP e precisa ser copiado; imagens não podem ser coladas como texto.


## `pubspec.yaml`

```yaml
name: projeto_telecom
description: "A new Flutter project."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: ^3.12.2

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.8
  crypto: ^3.0.8
  flutter_secure_storage: ^11.2.0
  http: ^1.6.0
  sqflite: ^2.4.5
  path: ^1.9.1
  provider: ^6.1.5+1
  geolocator: ^14.1.2
  image_picker: ^1.2.4
  path_provider: ^2.1.6

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^6.0.0
  sqflite_common_ffi: ^2.4.5

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true
  assets:
    - assets/images/logo.png

  # To add assets to your application, add an assets section, like this:
  # assets:
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Schyler
  #     fonts:
  #       - asset: fonts/Schyler-Regular.ttf
  #       - asset: fonts/Schyler-Italic.ttf
  #         style: italic
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package
```


## `lib/data/datasources/database_helper.dart`

```dart
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
```


## `lib/data/datasources/local_datasource.dart`

```dart
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
```


## `lib/data/datasources/remote_datasource.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/atendimento_model.dart';
import '../models/chamado_model.dart';
import '../models/historico_item.dart';

class ApiException implements Exception {
  final int statusCode;
  final String mensagem;
  const ApiException(this.statusCode, this.mensagem);

  bool get sessaoInvalida => statusCode == 401 || statusCode == 403;

  @override
  String toString() => mensagem;
}

class LoginResultado {
  final String token;
  final int? usuarioId;
  const LoginResultado(this.token, this.usuarioId);
}

class RemoteDatasource {
  static const String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  final http.Client _client;

  RemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  Future<LoginResultado> login(String email, String senhaHmac) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'senha_hmac': senhaHmac}),
        )
        .timeout(const Duration(seconds: 15));

    final corpo = _objeto(response);
    if (response.statusCode != 200 || corpo['sucesso'] != true) {
      throw ApiException(
        response.statusCode,
        (corpo['mensagem'] ?? 'Não foi possível autenticar.').toString(),
      );
    }

    final dados = corpo['dados'];
    if (dados is! Map || dados['token'] is! String) {
      throw const FormatException('Token ausente na resposta de login.');
    }
    final token = (dados['token'] as String).trim();
    if (token.isEmpty) throw const FormatException('Token vazio.');
    final usuario = dados['usuario'];
    final id = usuario is Map ? int.tryParse((usuario['id']).toString()) : null;
    return LoginResultado(token, id);
  }

  Future<List<ChamadoModel>> listarChamados(String token) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/chamados'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    final corpo = _objeto(response);
    if (response.statusCode != 200 || corpo['sucesso'] != true) {
      throw ApiException(
        response.statusCode,
        (corpo['mensagem'] ?? 'Falha na lista de chamados.').toString(),
      );
    }
    final dados = corpo['dados'];
    if (dados is! List) {
      throw const FormatException('A API não devolveu dados em lista.');
    }
    return dados
        .map((item) => ChamadoModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<String?> enviarAtendimento(
    String token,
    AtendimentoModel atendimento,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/atendimento'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll({
      'chamado_id': atendimento.chamadoId.toString(),
      'categoria_tecnico': atendimento.categoria,
      'descricao_procedimento': atendimento.descricao,
      'data_resolucao': atendimento.dataConclusao,
    });

    final caminhoFoto = atendimento.fotoPath;
    if (caminhoFoto != null && caminhoFoto.isNotEmpty) {
      if (!await File(caminhoFoto).exists()) {
        throw const FileSystemException('Foto do atendimento não encontrada.');
      }
      request.files.add(await http.MultipartFile.fromPath('foto', caminhoFoto));
    }

    final stream = await _client.send(request).timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(stream);
    final corpo = _objeto(response);
    if (response.statusCode != 201 || corpo['sucesso'] != true) {
      throw ApiException(
        response.statusCode,
        (corpo['mensagem'] ?? 'Falha ao sincronizar atendimento.').toString(),
      );
    }
    final dados = corpo['dados'];
    return dados is Map ? dados['foto_url']?.toString() : null;
  }

  Future<List<HistoricoItem>> listarHistorico(String token) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/historico'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 12));
    final corpo = _objeto(response);
    if (response.statusCode != 200 || corpo['sucesso'] != true) {
      throw ApiException(
        response.statusCode,
        (corpo['mensagem'] ?? 'Falha ao carregar histórico.').toString(),
      );
    }
    final dados = corpo['dados'];
    if (dados is! List) throw const FormatException('Histórico inválido.');
    return dados
        .map((item) => HistoricoItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Map<String, dynamic> _objeto(http.Response response) {
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map) throw const FormatException('Resposta JSON inválida.');
    return Map<String, dynamic>.from(json);
  }
}
```


## `lib/data/datasources/token_store.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStore {
  Future<void> salvar(String token);
  Future<String?> ler();
  Future<void> apagar();
}

class SecureTokenStore implements TokenStore {
  static const _chave = 'auth_token';
  final FlutterSecureStorage storage;
  const SecureTokenStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<void> salvar(String token) =>
      storage.write(key: _chave, value: token);

  @override
  Future<String?> ler() => storage.read(key: _chave);

  @override
  Future<void> apagar() => storage.delete(key: _chave);
}
```


## `lib/data/models/atendimento_model.dart`

```dart
class AtendimentoModel {
  final int? id;
  final int chamadoId;
  final String categoria;
  final String descricao;
  final String dataConclusao;
  final String? fotoPath;
  final String? fotoUrl;
  final int sincronizado;

  const AtendimentoModel({
    this.id,
    required this.chamadoId,
    required this.categoria,
    required this.descricao,
    required this.dataConclusao,
    this.fotoPath,
    this.fotoUrl,
    this.sincronizado = 0,
  });

  factory AtendimentoModel.fromJson(Map<String, dynamic> json) =>
      AtendimentoModel(
        id: int.tryParse((json['atendimento_id'] ?? json['id']).toString()),
        chamadoId: int.parse((json['chamado_id'] ?? json['chamadoId']).toString()),
        categoria: (json['categoria_tecnico'] ?? '').toString(),
        descricao: (json['descricao_procedimento'] ?? '').toString(),
        dataConclusao: (json['data_resolucao'] ?? '').toString(),
        fotoUrl: json['foto_url']?.toString(),
        sincronizado: 1,
      );

  Map<String, dynamic> toJson() => {
        'chamado_id': chamadoId,
        'categoria_tecnico': categoria,
        'descricao_procedimento': descricao,
        'data_resolucao': dataConclusao,
      };

  factory AtendimentoModel.fromMap(Map<String, dynamic> map) =>
      AtendimentoModel(
        id: map['id'] as int?,
        chamadoId: map['chamadoId'] as int,
        categoria: map['categoria'] as String,
        descricao: map['descricao'] as String,
        dataConclusao: map['dataConclusao'] as String,
        fotoPath: map['fotoPath'] as String?,
        fotoUrl: map['fotoUrl'] as String?,
        sincronizado: map['sincronizado'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chamadoId': chamadoId,
        'categoria': categoria,
        'descricao': descricao,
        'dataConclusao': dataConclusao,
        'fotoPath': fotoPath,
        'fotoUrl': fotoUrl,
        'sincronizado': sincronizado,
      };
}
```


## `lib/data/models/chamado_model.dart`

```dart
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
```


## `lib/data/models/historico_item.dart`

```dart
class HistoricoItem {
  final int? id;
  final int chamadoId;
  final String codigoCliente;
  final String nomeCliente;
  final String categoria;
  final String descricao;
  final String dataConclusao;
  final String? fotoPath;
  final String? fotoUrl;
  final bool sincronizado;

  const HistoricoItem({
    this.id,
    required this.chamadoId,
    required this.codigoCliente,
    required this.nomeCliente,
    required this.categoria,
    required this.descricao,
    required this.dataConclusao,
    this.fotoPath,
    this.fotoUrl,
    required this.sincronizado,
  });

  factory HistoricoItem.fromMap(Map<String, dynamic> map) => HistoricoItem(
        id: map['id'] as int?,
        chamadoId: map['chamadoId'] as int,
        codigoCliente: (map['codigoCliente'] ?? '').toString(),
        nomeCliente: (map['nomeCliente'] ?? '').toString(),
        categoria: (map['categoria'] ?? '').toString(),
        descricao: (map['descricao'] ?? '').toString(),
        dataConclusao: (map['dataConclusao'] ?? '').toString(),
        fotoPath: map['fotoPath']?.toString(),
        fotoUrl: map['fotoUrl']?.toString(),
        sincronizado: map['sincronizado'] == 1,
      );

  factory HistoricoItem.fromJson(Map<String, dynamic> json) {
    final dados = json['atendimento'] is Map
        ? json['atendimento'] as Map
        : <String, dynamic>{};
    return HistoricoItem(
      id: int.tryParse((dados['id'] ?? '').toString()),
      chamadoId: int.parse((json['chamado_id'] ?? json['id']).toString()),
      codigoCliente: (json['codigo_cliente'] ?? '').toString(),
      nomeCliente: (json['nome_cliente'] ?? '').toString(),
      categoria: (dados['categoria_tecnico'] ?? '').toString(),
      descricao: (dados['descricao_procedimento'] ?? '').toString(),
      dataConclusao: (dados['data_resolucao'] ?? '').toString(),
      fotoUrl: dados['foto_url']?.toString(),
      sincronizado: true,
    );
  }
}
```


## `lib/data/models/usuario_model.dart`

```dart
class UsuarioModel {
  final int? id;
  final String email;
  final String nome;
  final String? token;

  const UsuarioModel({
    this.id,
    required this.email,
    this.nome = '',
    this.token,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    final dados = json['dados'] is Map ? json['dados'] as Map : json;
    final usuario = dados['usuario'] is Map ? dados['usuario'] as Map : dados;
    return UsuarioModel(
      id: int.tryParse((usuario['id'] ?? '').toString()),
      email: (usuario['email'] ?? '').toString(),
      nome: (usuario['nome'] ?? '').toString(),
      token: dados['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'email': email, 'nome': nome, 'token': token};

  factory UsuarioModel.fromMap(Map<String, dynamic> map) => UsuarioModel(
        id: map['id'] as int?,
        email: (map['email'] ?? '').toString(),
        nome: (map['nome'] ?? '').toString(),
        token: map['token']?.toString(),
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'email': email, 'nome': nome, 'token': token};
}
```


## `lib/data/repositories/atendimentos_repository.dart`

```dart
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
```


## `lib/data/repositories/auth_repository.dart`

```dart
import '../datasources/remote_datasource.dart';
import '../datasources/token_store.dart';

class AuthRepository {
  final RemoteDatasource remoto;
  final TokenStore tokens;

  AuthRepository({RemoteDatasource? remoto, TokenStore? tokens})
      : remoto = remoto ?? RemoteDatasource(),
        tokens = tokens ?? const SecureTokenStore();

  // A ViewModel calcula HMAC-SHA256 antes desta chamada.
  Future<bool> login(String email, String senhaHmac) async {
    final resultado = await remoto.login(email, senhaHmac);
    await tokens.salvar(resultado.token);
    return true;
  }

  Future<String?> getToken() => tokens.ler();
  Future<void> logout() => tokens.apagar();
}
```


## `lib/data/repositories/chamados_repository.dart`

```dart
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
```


## `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local_datasource.dart';
import 'data/datasources/remote_datasource.dart';
import 'data/datasources/token_store.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chamados_repository.dart';
import 'data/repositories/atendimentos_repository.dart';
import 'viewModel/auth_viewmodel.dart';
import 'viewModel/chamados_viewmodel.dart';
import 'viewModel/atendimento_viewmodel.dart';
import 'viewModel/historico_viewmodel.dart';
import 'view/splash_view.dart';
import 'view/login_view.dart';
import 'view/home_view.dart';
import 'view/atendimento_view.dart';
import 'view/historico_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final remoto = RemoteDatasource();
  final local = LocalDatasource();
  final autenticacao = AuthRepository(
    remoto: remoto,
    tokens: const SecureTokenStore(),
  );
  final chamados = ChamadosRepository(
    local: local,
    remoto: remoto,
    autenticacao: autenticacao,
  );
  final atendimentos = AtendimentosRepository(
    local: local,
    remoto: remoto,
    autenticacao: autenticacao,
  );

  runApp(MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: autenticacao),
      Provider<ChamadosRepository>.value(value: chamados),
      Provider<AtendimentosRepository>.value(value: atendimentos),
      ChangeNotifierProvider(create: (_) => AuthViewModel(autenticacao)),
      ChangeNotifierProvider(create: (_) => ChamadosViewModel(chamados)),
      ChangeNotifierProvider(create: (_) => AtendimentoViewModel(atendimentos)),
      ChangeNotifierProvider(create: (_) => HistoricoViewModel(atendimentos)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telecom ISP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashView(),
        '/login': (_) => const LoginView(),
        '/home': (_) => const HomeView(),
        '/atendimento': (_) => const AtendimentoView(),
        '/historico': (_) => const HistoricoView(),
        '/detalhes': (_) => const AtendimentoView(),
      },
    );
  }
}
```


## `lib/services/location_service.dart`

```dart
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class Coordenada {
  final double latitude;
  final double longitude;
  const Coordenada(this.latitude, this.longitude);
}

class LocationService {
  Future<Coordenada?> obterLocalizacao() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));
      return Coordenada(posicao.latitude, posicao.longitude);
    } catch (_) {
      return null;
    }
  }

  // Fórmula de Haversine. Funciona sem rede e facilita o teste unitário.
  static double distanciaKm(Coordenada origem, Coordenada destino) {
    const raioTerraKm = 6371.0;
    const grausEmRadianos = math.pi / 180;
    final deltaLat = (destino.latitude - origem.latitude) * grausEmRadianos;
    final deltaLon = (destino.longitude - origem.longitude) * grausEmRadianos;
    final lat1 = origem.latitude * grausEmRadianos;
    final lat2 = destino.latitude * grausEmRadianos;
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2);
    final limitado = a.clamp(0.0, 1.0).toDouble();
    return 2 * raioTerraKm *
        math.atan2(math.sqrt(limitado), math.sqrt(1 - limitado));
  }
}
```


## `lib/services/photo_service.dart`

```dart
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  final ImagePicker picker;
  PhotoService({ImagePicker? picker}) : picker = picker ?? ImagePicker();

  Future<String?> selecionar(ImageSource origem) async {
    final selecionada = await picker.pickImage(
      source: origem,
      imageQuality: 65,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
    if (selecionada == null) return null;
    final foto = File(selecionada.path);
    const tamanhoMaximo = 5 * 1024 * 1024;
    if (await foto.length() > tamanhoMaximo) {
      throw StateError('A foto precisa ter no máximo 5 MB.');
    }

    final extensao = path.extension(selecionada.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extensao)) {
      throw StateError('Use fotos JPG, PNG ou WEBP.');
    }
    final pasta = Directory(path.join(
      (await getApplicationDocumentsDirectory()).path,
      'fotos_atendimentos',
    ));
    await pasta.create(recursive: true);
    final destino = path.join(
      pasta.path,
      'foto_${DateTime.now().microsecondsSinceEpoch}$extensao',
    );
    await foto.copy(destino);
    return destino;
  }
}
```


## `lib/view/atendimento_view.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/models/chamado_model.dart';
import '../services/photo_service.dart';
import '../viewModel/atendimento_viewmodel.dart';

class AtendimentoView extends StatefulWidget {
  const AtendimentoView({super.key});

  @override
  State<AtendimentoView> createState() => _AtendimentoViewState();
}

class _AtendimentoViewState extends State<AtendimentoView> {
  final _formKey = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _fotos = PhotoService();
  String? _categoria;
  String? _fotoPath;

  static const categorias = [
    'Conector / fibra óptica',
    'Roteador ou Wi-Fi',
    'Instalação / cabeamento',
    'Equipamento defeituoso',
    'Configuração de rede',
    'Outro',
  ];

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (origem == null) return;
    try {
      final caminho = await _fotos.selecionar(origem);
      if (mounted && caminho != null) setState(() => _fotoPath = caminho);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a foto: $erro')),
      );
    }
  }

  Future<void> _finalizar(ChamadoModel chamado) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }
    final vm = context.read<AtendimentoViewModel>();
    final sucesso = await vm.concluir(
      chamadoId: chamado.id,
      categoria: _categoria!,
      descricao: _descricao.text,
      fotoPath: _fotoPath,
    );
    if (!mounted) return;
    if (sucesso) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.erro ?? 'Erro ao salvar o atendimento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chamado = ModalRoute.of(context)!.settings.arguments as ChamadoModel;
    final salvando = context.watch<AtendimentoViewModel>().salvando;

    return Scaffold(
      appBar: AppBar(title: Text('Atendimento #${chamado.id}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chamado.nome,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Cliente: ${chamado.codigoCliente}'),
                    Text('Problema: ${chamado.resumo}'),
                    Text('Endereço: ${chamado.enderecoCompleto}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoria do parecer técnico *',
                border: OutlineInputBorder(),
              ),
              items: categorias
                  .map((texto) =>
                      DropdownMenuItem(value: texto, child: Text(texto)))
                  .toList(),
              onChanged: (valor) => setState(() => _categoria = valor),
              validator: (valor) =>
                  valor == null ? 'Selecione a categoria' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricao,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Procedimento realizado *',
                hintText: 'Descreva o que foi constatado e realizado',
                border: OutlineInputBorder(),
              ),
              validator: (texto) =>
                  (texto?.trim().length ?? 0) < 10
                      ? 'Escreva pelo menos 10 caracteres válidos'
                      : null,
            ),
            const SizedBox(height: 12),
            Text('Conclusão: ${DateTime.now().toLocal().toString().substring(0, 16)}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: salvando ? null : _escolherFoto,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Anexar foto (câmera ou galeria)'),
            ),
            if (_fotoPath != null) ...[
              const SizedBox(height: 12),
              Image.file(
                File(_fotoPath!),
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Text('Foto indisponível'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: salvando ? null : () => _finalizar(chamado),
              icon: salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('CONCLUIR E SALVAR OFFLINE'),
            ),
          ],
        ),
      ),
    );
  }
}
```


## `lib/view/historico_view.dart`

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/historico_item.dart';
import '../viewModel/historico_viewmodel.dart';

class HistoricoView extends StatefulWidget {
  const HistoricoView({super.key});

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoricoViewModel>().carregar();
    });
  }

  void _mostrarDetalhes(HistoricoItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atendimento #${item.chamadoId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Código: ${item.codigoCliente}'),
              Text('Cliente: ${item.nomeCliente}'),
              Text('Categoria: ${item.categoria}'),
              Text('Realizado: ${item.descricao}'),
              Text('Data: ${item.dataConclusao}'),
              const SizedBox(height: 12),
              if (item.sincronizado && item.fotoUrl?.isNotEmpty == true)
                Image.network(
                  item.fotoUrl!,
                  height: 180,
                  loadingBuilder: (context, child, loading) =>
                      loading == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) =>
                      const Text('Não foi possível abrir a foto remota.'),
                )
              else if (item.fotoPath?.isNotEmpty == true)
                Image.file(
                  File(item.fotoPath!),
                  height: 180,
                  errorBuilder: (_, __, ___) =>
                      const Text('Foto local indisponível.'),
                )
              else
                const Text('Atendimento sem foto.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoricoViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Atendimentos'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendentes',
            onPressed: vm.sincronizando ? null : vm.sincronizar,
            icon: vm.sincronizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: vm.pesquisar,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por ID ou código do cliente',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Card(child: Center(child: Text('Pendentes: ${vm.pendentes}'))),
              Card(child: Center(child: Text('Enviados: ${vm.enviados}'))),
            ],
          ),
          if (vm.todosEnviados && vm.itens.isNotEmpty)
            const Text('Todos os atendimentos estão sincronizados.'),
          if (vm.mensagem != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(vm.mensagem!, textAlign: TextAlign.center),
            ),
          Expanded(
            child: vm.carregando
                ? const Center(child: CircularProgressIndicator())
                : vm.filtrados.isEmpty
                    ? const Center(child: Text('Nenhum atendimento encontrado.'))
                    : ListView.builder(
                        itemCount: vm.filtrados.length,
                        itemBuilder: (context, index) {
                          final item = vm.filtrados[index];
                          return ListTile(
                            title: Text('OS #${item.chamadoId} — ${item.codigoCliente}'),
                            subtitle: Text(item.descricao, maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            trailing: Chip(
                              label: Text(item.sincronizado
                                  ? 'Sincronizado'
                                  : 'Pendente de envio'),
                              backgroundColor: item.sincronizado
                                  ? Colors.green.shade100
                                  : Colors.amber.shade100,
                            ),
                            onTap: () => _mostrarDetalhes(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```


## `lib/view/home_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/chamado_model.dart';
import '../data/repositories/auth_repository.dart';
import '../viewModel/chamados_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChamadosViewModel>().carregarChamados();
    });
  }

  Future<void> _sair() async {
    await context.read<AuthRepository>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _abrirAtendimento(ChamadoModel chamado) async {
    final concluido = await Navigator.pushNamed(
      context, '/atendimento', arguments: chamado,
    );
    if (mounted && concluido == true) {
      await context.read<ChamadosViewModel>().carregarChamados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atendimento salvo no aparelho. Sincronize quando houver internet.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChamadosViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          IconButton(
            tooltip: 'Histórico e sincronização',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/historico'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
        ],
      ),
      body: Column(
        children: [
          if (vm.usandoOffline)
            const MaterialBanner(
              content: Text('Modo offline: mostrando chamados salvos no aparelho.'),
              leading: Icon(Icons.cloud_off),
              actions: [SizedBox.shrink()],
            ),
          if (vm.atualizando) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _conteudo(vm)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Atualizar chamados',
        onPressed: vm.atualizando ? null : vm.carregarChamados,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _conteudo(ChamadosViewModel vm) {
    if (vm.isLoading && vm.chamados.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.chamados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vm.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (vm.chamados.isEmpty) {
      return const Center(child: Text('Nenhum chamado ativo encontrado.'));
    }

    return RefreshIndicator(
      onRefresh: vm.carregarChamados,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vm.chamados.length,
        itemBuilder: (context, index) {
          final chamado = vm.chamados[index];
          final distancia = vm.distancias[chamado.id];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _abrirAtendimento(chamado),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chamado.nome,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (distancia != null)
                          Chip(label: Text('${distancia.toStringAsFixed(1)} km'))
                        else
                          const Chip(label: Text('GPS indisponível')),
                      ],
                    ),
                    Text('Código: ${chamado.codigoCliente}'),
                    Text('Categoria: ${chamado.categoria}'),
                    const SizedBox(height: 8),
                    Text(chamado.resumo),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.place, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(chamado.enderecoCompleto)),
                    ]),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Abrir atendimento',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```


## `lib/view/login_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModel/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _realizarLogin() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Ocultar teclado após clicar em entrar
      FocusScope.of(context).unfocus();

      // Chama a ViewModel para assinar e enviar os dados
      final sucesso = await authViewModel.fazerLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (sucesso) {
        if (!mounted) return;
        // Navega para a Home (substitui a rota atual para não voltar ao login)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        // Mostra o erro (ex: credenciais incorretas) num SnackBar vermelho
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Erro ao fazer login'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escutamos o estado da ViewModel para mostrar a rodinha de carregamento
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logótipo / Ícone da App
                    Image.asset('assets/images/logo.png', width:74, height:74),
                    const SizedBox(height: 16),
                    const Text(
                      'Telecom ISP',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    
                    // Campo de E-mail
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail institucional',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o seu e-mail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de Palavra-passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Palavra-passe',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a sua palavra-passe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Botão de Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _realizarLogin,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ENTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```


## `lib/view/splash_view.dart`

```dart
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await _authRepository.getToken();
    
    if (!mounted) return;
    
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width:100, height:100),
            const SizedBox(height: 16),
            const Text(
              'Telecom ISP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
```


## `lib/viewModel/atendimento_viewmodel.dart`

```dart
import 'package:flutter/material.dart';

import '../data/repositories/atendimentos_repository.dart';

class AtendimentoViewModel extends ChangeNotifier {
  final AtendimentosRepository repositorio;
  bool salvando = false;
  String? erro;

  AtendimentoViewModel(this.repositorio);

  Future<bool> concluir({
    required int chamadoId,
    required String categoria,
    required String descricao,
    String? fotoPath,
  }) async {
    if (categoria.isEmpty || descricao.trim().length < 10) {
      erro = 'Informe a categoria e uma descrição com 10 caracteres.';
      notifyListeners();
      return false;
    }

    salvando = true;
    erro = null;
    notifyListeners();
    try {
      await repositorio.concluir(
        chamadoId: chamadoId,
        categoria: categoria,
        descricao: descricao,
        fotoPath: fotoPath,
      );
      return true;
    } catch (e) {
      erro = 'Falha ao salvar no dispositivo: $e';
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }
}
```


## `lib/viewModel/auth_viewmodel.dart`

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  // Chave Secreta Compartilhada da Turma (RF03)
  final String _secretKey = 'ISP_TECH_SENAI_2026_xK9#mQ2\$vL8!zP4';

  bool isLoading = false;
  String? errorMessage;

  AuthViewModel(this._authRepository);

  // Método rigoroso de encriptação HMAC-SHA256
  String _gerarHmacSha256(String password) {
    var key = utf8.encode(_secretKey);
    var bytes = utf8.encode(password);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> fazerLogin(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Assina a palavra-passe localmente ANTES de enviar
      final hashedSenha = _gerarHmacSha256(password);

      // 2. Envia para a API através do Repository
      final sucesso = await _authRepository.login(email, hashedSenha);
      if (!sucesso) {
        throw Exception('Não foi possível autenticar com esses dados.');
      }
      
      isLoading = false;
      notifyListeners();
      return true; // Login com sucesso
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false; // Falha no login
    }
  }
}
```


## `lib/viewModel/chamados_viewmodel.dart`

```dart
import 'package:flutter/material.dart';

import '../data/models/chamado_model.dart';
import '../data/repositories/chamados_repository.dart';
import '../services/location_service.dart';

class ChamadosViewModel extends ChangeNotifier {
  final ChamadosRepository repositorio;
  final LocationService localizacao;

  List<ChamadoModel> chamados = [];
  Map<int, double> distancias = {};
  bool isLoading = false;
  bool atualizando = false;
  bool usandoOffline = false;
  String? errorMessage;

  ChamadosViewModel(
    this.repositorio, {
    LocationService? localizacao,
  }) : localizacao = localizacao ?? LocationService();

  Future<void> carregarChamados() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // O SQLite é a primeira fonte, inclusive sem internet.
      await _mostrar(await repositorio.listarLocais());
      isLoading = false;
      atualizando = true;
      notifyListeners();

      final atualizados = await repositorio.atualizarDaApi();
      await _mostrar(atualizados);
      usandoOffline = false;
    } catch (erro) {
      usandoOffline = true;
      if (chamados.isEmpty) {
        errorMessage =
            'Sem rede ou sem chamados salvos. Entre com internet na primeira vez. ($erro)';
      }
    } finally {
      isLoading = false;
      atualizando = false;
      notifyListeners();
    }
  }

  Future<void> _mostrar(List<ChamadoModel> lista) async {
    final posicao = await localizacao.obterLocalizacao();
    distancias = {};
    if (posicao != null) {
      for (final chamado in lista) {
        distancias[chamado.id] = LocationService.distanciaKm(
          posicao,
          Coordenada(chamado.latitude, chamado.longitude),
        );
      }
      lista.sort((a, b) =>
          (distancias[a.id] ?? double.infinity)
              .compareTo(distancias[b.id] ?? double.infinity));
    }
    chamados = lista;
    notifyListeners();
  }
}
```


## `lib/viewModel/historico_viewmodel.dart`

```dart
import 'package:flutter/material.dart';

import '../data/models/historico_item.dart';
import '../data/repositories/atendimentos_repository.dart';

class HistoricoViewModel extends ChangeNotifier {
  final AtendimentosRepository repositorio;
  List<HistoricoItem> itens = [];
  String pesquisa = '';
  bool carregando = false;
  bool sincronizando = false;
  String? mensagem;

  HistoricoViewModel(this.repositorio);

  List<HistoricoItem> get filtrados => itens.where((item) {
        final texto = pesquisa.trim().toLowerCase();
        return item.chamadoId.toString().contains(texto) ||
            item.codigoCliente.toLowerCase().contains(texto);
      }).toList();

  int get pendentes => itens.where((item) => !item.sincronizado).length;
  int get enviados => itens.where((item) => item.sincronizado).length;
  bool get todosEnviados => itens.every((item) => item.sincronizado);

  void pesquisar(String valor) {
    pesquisa = valor;
    notifyListeners();
  }

  Future<void> carregar() async {
    carregando = true;
    mensagem = null;
    notifyListeners();
    try {
      itens = await repositorio.carregarHistorico();
    } catch (erro) {
      mensagem = 'Não foi possível ler o histórico: $erro';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> sincronizar() async {
    sincronizando = true;
    mensagem = null;
    notifyListeners();
    try {
      final resultado = await repositorio.sincronizarPendentes();
      mensagem = '${resultado.enviados} enviado(s), ${resultado.falhas} pendente(s).';
      itens = await repositorio.carregarHistorico();
    } catch (erro) {
      mensagem = 'Sem conexão para sincronizar: $erro';
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }
}
```


## `test/auth_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_telecom/data/datasources/remote_datasource.dart';
import 'package:projeto_telecom/data/datasources/token_store.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';

class TokenStoreMemoria implements TokenStore {
  String? token;
  @override
  Future<void> salvar(String valor) async {
    token = valor;
  }
  @override
  Future<String?> ler() async => token;
  @override
  Future<void> apagar() async {
    token = null;
  }
}

class RemoteLoginFake extends RemoteDatasource {
  @override
  Future<LoginResultado> login(String email, String senhaHmac) async =>
      const LoginResultado('token-valido', 1);
}

void main() {
  test('repositório salva e apaga token da sessão', () async {
    final memoria = TokenStoreMemoria();
    final auth = AuthRepository(remoto: RemoteLoginFake(), tokens: memoria);

    expect(await auth.login('teste@exemplo.com', 'hash'), isTrue);
    expect(await auth.getToken(), 'token-valido');

    await auth.logout();
    expect(await auth.getToken(), isNull);
  });
}
```


## `test/auth_viewmodel_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';
import 'package:projeto_telecom/viewModel/auth_viewmodel.dart';

class _AuthRepositoryTeste extends AuthRepository {
  final bool resultado;
  String? senhaRecebida;

  _AuthRepositoryTeste(this.resultado);

  @override
  Future<bool> login(String email, String senhaAssinada) async {
    senhaRecebida = senhaAssinada;
    return resultado;
  }
}

void main() {
  test('login rejeitado não é tratado como sucesso', () async {
    final repositorio = _AuthRepositoryTeste(false);
    final viewModel = AuthViewModel(repositorio);

    final sucesso = await viewModel.fazerLogin('teste@exemplo.com', 'senha');

    expect(sucesso, isFalse);
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.isLoading, isFalse);
  });

  test('login envia HMAC-SHA256 em vez da senha original', () async {
    final repositorio = _AuthRepositoryTeste(true);
    final viewModel = AuthViewModel(repositorio);

    final sucesso = await viewModel.fazerLogin('teste@exemplo.com', 'senha');

    expect(sucesso, isTrue);
    expect(repositorio.senhaRecebida, hasLength(64));
    expect(repositorio.senhaRecebida, isNot('senha'));
    expect(viewModel.isLoading, isFalse);
  });
}
```


## `test/local_datasource_test.dart`

```dart
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
```


## `test/modelos_e_gps_test.dart`

```dart
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
```


## `test/remote_datasource_test.dart`

```dart
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
```


## `test/repositorios_test.dart`

```dart
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
```


## `test/widget_views_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';
import 'package:projeto_telecom/data/repositories/chamados_repository.dart';
import 'package:projeto_telecom/view/home_view.dart';
import 'package:projeto_telecom/view/login_view.dart';
import 'package:projeto_telecom/viewModel/auth_viewmodel.dart';
import 'package:projeto_telecom/viewModel/chamados_viewmodel.dart';

class _ChamadosViewModelTeste extends ChamadosViewModel {
  _ChamadosViewModelTeste() : super(ChamadosRepository());

  @override
  Future<void> carregarChamados() async {
    chamados = [
      const ChamadoModel(
        id: 25,
        codigoCliente: 'CLI-25',
        nome: 'Cliente Exemplo',
        categoria: 'Fibra',
        resumo: 'Cabo rompido',
        endereco: 'Rua das Flores',
        latitude: -27.0,
        longitude: -48.0,
        status: 'ativo',
      ),
    ];
    notifyListeners();
  }
}

void main() {
  testWidgets('tela de login exibe campos e botão', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(AuthRepository()),
        child: const MaterialApp(home: LoginView()),
      ),
    );
    expect(find.text('E-mail institucional'), findsOneWidget);
    expect(find.text('Palavra-passe'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('Home exibe card com informações do chamado', (tester) async {
    final vm = _ChamadosViewModelTeste();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>(create: (_) => AuthRepository()),
          ChangeNotifierProvider<ChamadosViewModel>.value(value: vm),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    expect(find.text('Cliente Exemplo'), findsOneWidget);
    expect(find.text('Código: CLI-25'), findsOneWidget);
    expect(find.text('Abrir atendimento'), findsOneWidget);
  });
}
```


## `CONFIGURAR_ANDROID.md`

# Configuração Android necessária

O ZIP contém apenas o código `lib/`, os testes e os recursos visuais.
Não substitua toda a pasta `android/` do seu projeto.

## 1. AndroidManifest.xml

No arquivo `android/app/src/main/AndroidManifest.xml`, dentro de
`<manifest>` e **antes** de `<application>`, confira estas permissões:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

A localização é solicitada apenas quando a Home precisa ordenar os chamados.
Não é necessário liberar localização em segundo plano.

O `image_picker` usa os recursos do Android e normalmente não exige
configuração adicional para abrir a câmera ou a galeria.

## 2. SDK e AndroidX

A documentação atual do `geolocator` recomenda `compileSdk 35` ou superior.

Se o projeto usa `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35
}
```

Se usa `android/app/build.gradle` (Groovy):

```groovy
android {
    compileSdkVersion 35
}
```

Confira `android/gradle.properties`:

```properties
android.useAndroidX=true
android.enableJetifier=true
```

Não copie cegamente os exemplos sobre o arquivo inteiro: preserve as
configurações do Flutter, namespace e applicationId existentes.

## 3. Recompilar de verdade

Ao instalar plugins novos, pare o emulador em execução pelo terminal e rode:

```powershell
flutter clean
flutter pub get
flutter run
```

Se ainda encontrar `10.0.2.2`, verifique a pasta atual do terminal com
`Get-Location`. Você precisa executar a pasta que contém o novo `lib/data/`.

## 4. Permissões no emulador

Aceite a solicitação de localização. Caso o GPS do emulador não esteja ativo,
a Home exibe "GPS indisponível" e mantém os chamados listados.


## `CHECKLIST_ENTREGA.md`

# Checklist de entrega - Projeto Telecom

## Código preparado neste pacote

- [x] RF01 - Models de usuário, chamado e atendimento.
- [x] RF02 - Splash com abertura e leitura de token.
- [x] RF03 - Login HMAC-SHA256 com chave compartilhada da turma.
- [x] RF04 - Persistência do token via flutter_secure_storage.
- [x] RF05 - SQLite e modo offline para os chamados carregados.
- [x] RF06 - Home com chamados ativos e ListView.builder.
- [x] RF07 - Distância GPS usando Haversine e ordenação.
- [x] RF08 - Detalhes do chamado e indicação de conexão offline.
- [x] RF09 - Formulário de atendimento com os campos solicitados.
- [x] RF10 - Validação obrigatória e descrição com 10 caracteres.
- [x] RF11 - Foto pela câmera/galeria, guardada no aplicativo.
- [x] RF12 - Conclusão offline e atualização do status no SQLite.
- [x] RF13 - Envio multipart POST /api/atendimento com HTTP 201.
- [x] RF14 - Histórico local e consulta da API.
- [x] RF15 - Pesquisa por número do chamado ou código do cliente.
- [x] RF16 - Visualização de foto local ou da API.
- [x] Testes unitários escritos para models, datasources e repositórios.
- [x] Dois testes de interface (`test/widget_views_test.dart`).
- [x] GridView, Image.asset, filtros/ordenação e README.
- [x] Roteiro com commits para GitFlow.

## A fazer no computador do aluno antes de entregar

- [ ] Substituir a pasta `lib/` inteira, não mesclar com o código antigo.
- [ ] Copiar `pubspec.yaml`, `assets/` e `test/` para a raiz.
- [ ] Configurar permissões Android e `compileSdk` no projeto original.
- [ ] Rodar `VERIFICAR_INSTALACAO.ps1` (ou verificar os caminhos manualmente).
- [ ] Executar `flutter clean`, `flutter pub get`, `flutter analyze` e corrigir
      eventuais problemas de SDK ou configurações locais.
- [ ] Executar `flutter test`; os testes ainda **não foram executados** aqui.
- [ ] Testar login com as credenciais fornecidas pelo professor.
- [ ] Testar o fluxo com e sem internet, localização, câmera e histórico.
- [ ] Revisar `git status` e criar os commits no repositório original.
- [ ] Fazer push seguindo o fluxo do professor e conferir permissões.
- [ ] Gravar o vídeo demonstrativo e entregar os links no AVA.

**Limite importante:** O SDK Flutter não está instalado no ambiente que
produziu este código, por isso os itens marcados como feitos significam
**implementados no código**, não validados em emulador ou aprovados pelo
professor. O Manifest Android não foi fornecido e exige edição manual.


## `GUIA_COMMITS.md`

# Commits GitFlow - Projeto Telecom

**Não execute os comandos de push se o projeto já foi submetido e o professor
não autorizou mudanças após a entrega.**

Estes comandos são sugestões para o seu **repositório real**. O ZIP fornecido
não tem histórico `.git`; nenhum commit foi criado no seu GitHub por este
assistente.

Antes de começar, faça backup e confirme que instalou o pacote na pasta certa:

```bash
git status
git branch
```

Se já houver mudanças suas sem commit, preserve-as antes de trocar de branch.
Partindo de uma `develop` limpa, crie uma feature branch:

```bash
git switch develop
git switch -c feature/isp-offline-completo
```

Depois de copiar os arquivos, faça os commits em grupos:

### Commit 1 - Modelos e SQLite

```bash
git add -A lib/data/models lib/data/datasources/database_helper.dart lib/data/datasources/local_datasource.dart
git commit -m "implementa modelos e persistencia SQLite offline"
```

### Commit 2 - API e login seguro

```bash
git add lib/data/datasources/remote_datasource.dart lib/data/datasources/token_store.dart lib/data/repositories/auth_repository.dart lib/viewModel/auth_viewmodel.dart
git commit -m "corrige integracao com API e autenticacao HMAC"
```

### Commit 3 - Home e GPS

```bash
git add lib/data/repositories/chamados_repository.dart lib/viewModel/chamados_viewmodel.dart lib/services/location_service.dart lib/view/home_view.dart
git commit -m "implementa Home offline e ordenacao por proximidade"
```

### Commit 4 - Atendimento e foto

```bash
git add lib/services/photo_service.dart lib/data/repositories/atendimentos_repository.dart lib/viewModel/atendimento_viewmodel.dart lib/view/atendimento_view.dart
git commit -m "implementa formulario de atendimento e foto local"
```

### Commit 5 - Histórico e sincronização

```bash
git add lib/viewModel/historico_viewmodel.dart lib/view/historico_view.dart
git commit -m "implementa historico e sincronizacao multipart"
```

### Commit 6 - Aplicação e dependências

```bash
git add lib/main.dart lib/view/login_view.dart lib/view/splash_view.dart pubspec.yaml assets/images/logo.png assets/images/logo.svg
git commit -m "integra navegacao e dependencias do aplicativo"
```

### Commit 7 - Testes e documentação

```bash
git add test README.md CONFIGURAR_ANDROID.md CHECKLIST_ENTREGA.md GUIA_COMMITS.md VERIFICAR_INSTALACAO.ps1
git commit -m "adiciona testes e documentacao de entrega"
```

**Atenção às pastas antigas:** se os diretórios antigos `lib/models/`,
`lib/repositories/`, `lib/datasources/` e `lib/view/detalhes_view.dart`
estavam versionados e agora foram removidos ao substituir a pasta `lib/`,
registre a remoção em um commit próprio após revisar com `git status`:

```bash
git add -u lib
git commit -m "remove estrutura antiga substituida por MVVM"
```

Só execute esse commit se houver remoções versionadas. Não gere commits vazios.

## Verificar antes de publicar

```bash
flutter analyze
flutter test
git status
git log --oneline -8
```

## Integrar branches (apenas com autorização para publicar)

```bash
git push -u origin feature/isp-offline-completo
git switch develop
git merge --no-ff feature/isp-offline-completo
git push origin develop
git switch main
git merge --no-ff develop
git push origin main
```

Se o repositório exigir Pull Request, utilize esse fluxo em vez de forçar push.
Confirme que `rafaelhaguiar` e `lab365-operacao` têm acesso ao repositório
privado e que o vídeo e os links foram enviados pelo AVA.
