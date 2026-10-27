import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chamado_model.dart';
import '../datasources/database_helper.dart';

class ChamadosRepository {
  final String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Busca os chamados e aplica a lógica Offline-First
  Future<List<ChamadoModel>> getChamados(String token) async {
    try {
      // 1. Tenta buscar os dados mais recentes da API
      final response = await http.get(
        Uri.parse('$baseUrl/chamados'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      ).timeout(const Duration(seconds: 10)); // Timeout para não ficar preso sem rede

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<ChamadoModel> chamadosApi = data.map((json) => ChamadoModel.fromJson(json)).toList();

        // 2. Se a API respondeu com sucesso, atualiza o cache local no SQLite
        final db = await _dbHelper.database;
        await db.delete('chamados'); // Limpa a tabela antiga
        
        for (var chamado in chamadosApi) {
          await db.insert('chamados', chamado.toMap());
        }

        return chamadosApi;
      } else {
        // 3. Se a API retornar erro (ex: servidor em baixo), tenta carregar do banco local
        return await _getChamadosLocais();
      }
    } catch (e) {
      // 4. Se não houver internet (exceção de rede ou timeout), carrega do SQLite
      return await _getChamadosLocais();
    }
  }

  // Método auxiliar privado para ler do SQLite
  Future<List<ChamadoModel>> _getChamadosLocais() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('chamados');
    
    return List.generate(maps.length, (i) {
      return ChamadoModel.fromMap(maps[i]);
    });
  }
}