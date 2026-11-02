import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:projeto_telecom/data/models/chamado_model.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';
import 'package:projeto_telecom/data/repositories/chamados_repository.dart';
import 'package:projeto_telecom/view/home_view.dart';
import 'package:projeto_telecom/view/login_view.dart';
import 'package:projeto_telecom/viewModel/auth_viewmodel.dart';
import 'package:projeto_telecom/viewModel/chamados_viewmodel.dart';

class _ChamadosViewModelTeste extends ChamadosViewModel {
  _ChamadosViewModelTeste() : super(ChamadosRepository());

  @override
  Future<void> carregarChamados() async {
    chamados = [
      const ChamadoModel(
        id: 25,
        codigoCliente: 'CLI-25',
        nome: 'Cliente Exemplo',
        categoria: 'Fibra',
        resumo: 'Cabo rompido',
        endereco: 'Rua das Flores',
        latitude: -27.0,
        longitude: -48.0,
        status: 'ativo',
      ),
    ];
    notifyListeners();
  }
}

void main() {
  testWidgets('tela de login exibe campos e botão', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(AuthRepository()),
        child: const MaterialApp(home: LoginView()),
      ),
    );
    expect(find.text('E-mail institucional'), findsOneWidget);
    expect(find.text('Palavra-passe'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('Home exibe card com informações do chamado', (tester) async {
    final vm = _ChamadosViewModelTeste();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>(create: (_) => AuthRepository()),
          ChangeNotifierProvider<ChamadosViewModel>.value(value: vm),
        ],
        child: const MaterialApp(home: HomeView()),
      ),
    );
    await tester.pump();
    expect(find.text('Cliente Exemplo'), findsOneWidget);
    expect(find.text('Código: CLI-25'), findsOneWidget);
    expect(find.text('Abrir atendimento'), findsOneWidget);
  });
}
