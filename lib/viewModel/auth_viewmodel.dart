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
