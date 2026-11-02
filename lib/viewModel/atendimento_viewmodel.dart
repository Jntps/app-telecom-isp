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
