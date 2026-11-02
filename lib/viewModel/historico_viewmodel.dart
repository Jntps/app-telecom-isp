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
