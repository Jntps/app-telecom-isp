import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/usuario_model.dart';

class AuthRepository {
  final String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  final _storage = const FlutterSecureStorage();

  Future<UsuarioModel> login(String email, String hashedSenha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      // O backend espera receber o email e a senha já encriptada
      body: jsonEncode({'email': email, 'senha': hashedSenha}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuario = UsuarioModel.fromJson(data);
      
      // Persiste o token de forma segura (RF04)
      if (usuario.token != null) {
        await _storage.write(key: 'auth_token', value: usuario.token);
      }
      return usuario;
    } else {
      throw Exception('Falha na autenticação. Verifique as credenciais.');
    }
  }

  // Utilizado pelo Splash Screen (RF02) para verificar auto-login
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }
}