import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/historico_item.dart';
import '../viewModel/historico_viewmodel.dart';

class HistoricoView extends StatefulWidget {
  const HistoricoView({super.key});

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoricoViewModel>().carregar();
    });
  }

  void _mostrarDetalhes(HistoricoItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atendimento #${item.chamadoId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Código: ${item.codigoCliente}'),
              Text('Cliente: ${item.nomeCliente}'),
              Text('Categoria: ${item.categoria}'),
              Text('Realizado: ${item.descricao}'),
              Text('Data: ${item.dataConclusao}'),
              const SizedBox(height: 12),
              if (item.sincronizado && item.fotoUrl?.isNotEmpty == true)
                Image.network(
                  item.fotoUrl!,
                  height: 180,
                  loadingBuilder: (context, child, loading) =>
                      loading == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) =>
                      const Text('Não foi possível abrir a foto remota.'),
                )
              else if (item.fotoPath?.isNotEmpty == true)
                Image.file(
                  File(item.fotoPath!),
                  height: 180,
                  errorBuilder: (_, __, ___) =>
                      const Text('Foto local indisponível.'),
                )
              else
                const Text('Atendimento sem foto.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoricoViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Atendimentos'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar pendentes',
            onPressed: vm.sincronizando ? null : vm.sincronizar,
            icon: vm.sincronizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: vm.pesquisar,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar por ID ou código do cliente',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              Card(child: Center(child: Text('Pendentes: ${vm.pendentes}'))),
              Card(child: Center(child: Text('Enviados: ${vm.enviados}'))),
            ],
          ),
          if (vm.todosEnviados && vm.itens.isNotEmpty)
            const Text('Todos os atendimentos estão sincronizados.'),
          if (vm.mensagem != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(vm.mensagem!, textAlign: TextAlign.center),
            ),
          Expanded(
            child: vm.carregando
                ? const Center(child: CircularProgressIndicator())
                : vm.filtrados.isEmpty
                    ? const Center(child: Text('Nenhum atendimento encontrado.'))
                    : ListView.builder(
                        itemCount: vm.filtrados.length,
                        itemBuilder: (context, index) {
                          final item = vm.filtrados[index];
                          return ListTile(
                            title: Text('OS #${item.chamadoId} — ${item.codigoCliente}'),
                            subtitle: Text(item.descricao, maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            trailing: Chip(
                              label: Text(item.sincronizado
                                  ? 'Sincronizado'
                                  : 'Pendente de envio'),
                              backgroundColor: item.sincronizado
                                  ? Colors.green.shade100
                                  : Colors.amber.shade100,
                            ),
                            onTap: () => _mostrarDetalhes(item),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
