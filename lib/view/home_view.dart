import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModel/chamados_viewmodel.dart';
import '../repositories/auth_repository.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChamadosViewModel>(context, listen: false).carregarChamados();
    });
  }

  void _fazerLogout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChamadosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _fazerLogout,
            tooltip: 'Terminar Sessão',
          ),
        ],
      ),
      body: _buildBody(viewModel),
      floatingActionButton: FloatingActionButton(
        onPressed: () => viewModel.carregarChamados(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody(ChamadosViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            viewModel.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (viewModel.chamados.isEmpty) {
      return const Center(
        child: Text('Nenhuma ordem de serviço encontrada.', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: viewModel.chamados.length,
      itemBuilder: (context, index) {
        final chamado = viewModel.chamados[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.build, color: Colors.white),
            ),
            title: Text('Chamado #${chamado.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${chamado.status}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        );
      },
    );
  }
}