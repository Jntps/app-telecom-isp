import 'package:flutter/material.dart';
import '../models/chamado_model.dart';

class DetalhesView extends StatelessWidget {
  const DetalhesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Recebe o objeto ChamadoModel passado pelo clique na HomeView
    final chamado = ModalRoute.of(context)!.settings.arguments as ChamadoModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chamado #${chamado.id}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informações da Ordem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('ID do Chamado: ${chamado.id}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Status Atual: ${chamado.status}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Botão onde vamos injetar a lógica de Geolocalização (RF06)
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Módulo de GPS será ativado aqui.')),
                );
              },
              icon: const Icon(Icons.location_on, size: 24),
              label: const Text('INICIAR ATENDIMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}