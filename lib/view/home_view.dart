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
