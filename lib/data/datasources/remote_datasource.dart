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
