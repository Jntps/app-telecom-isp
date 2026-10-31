import 'package:flutter/material.dart';
import '../models/chamado_model.dart';
import '../repositories/chamados_repository.dart';
import '../repositories/auth_repository.dart';

class ChamadosViewModel extends ChangeNotifier {
  final ChamadosRepository _chamadosRepository;
  final AuthRepository _authRepository;

  List<ChamadoModel> chamados = [];
  bool isLoading = false;
  String? errorMessage;

  // Recebe os repositórios por injeção de dependência
  ChamadosViewModel(this._chamadosRepository, this._authRepository);

  Future<void> carregarChamados() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); // Avisa a View para mostrar a rodinha de loading

    try {
      // 1. Recupera o token guardado de forma segura
      final token = await _authRepository.getToken();
      
      if (token == null || token.isEmpty) {
        errorMessage = 'Sessão inválida. Por favor, faça login novamente.';
        isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Pede os dados ao repositório (que fará a gestão API vs SQLite)
      chamados = await _chamadosRepository.getChamados(token);
      
    } catch (e) {
      errorMessage = 'Erro ao carregar chamados: $e';
    } finally {
      isLoading = false;
      notifyListeners(); // Avisa a View para remover o loading e atualizar a lista
    }
  }
}