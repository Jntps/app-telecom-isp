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
