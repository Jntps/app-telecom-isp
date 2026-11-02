import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local_datasource.dart';
import 'data/datasources/remote_datasource.dart';
import 'data/datasources/token_store.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chamados_repository.dart';
import 'data/repositories/atendimentos_repository.dart';
import 'viewModel/auth_viewmodel.dart';
import 'viewModel/chamados_viewmodel.dart';
import 'viewModel/atendimento_viewmodel.dart';
import 'viewModel/historico_viewmodel.dart';
import 'view/splash_view.dart';
import 'view/login_view.dart';
import 'view/home_view.dart';
import 'view/atendimento_view.dart';
import 'view/historico_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final remoto = RemoteDatasource();
  final local = LocalDatasource();
  final autenticacao = AuthRepository(
    remoto: remoto,
    tokens: const SecureTokenStore(),
  );
  final chamados = ChamadosRepository(
    local: local,
    remoto: remoto,
    autenticacao: autenticacao,
  );
  final atendimentos = AtendimentosRepository(
    local: local,
    remoto: remoto,
    autenticacao: autenticacao,
  );

  runApp(MultiProvider(
    providers: [
      Provider<AuthRepository>.value(value: autenticacao),
      Provider<ChamadosRepository>.value(value: chamados),
      Provider<AtendimentosRepository>.value(value: atendimentos),
      ChangeNotifierProvider(create: (_) => AuthViewModel(autenticacao)),
      ChangeNotifierProvider(create: (_) => ChamadosViewModel(chamados)),
      ChangeNotifierProvider(create: (_) => AtendimentoViewModel(atendimentos)),
      ChangeNotifierProvider(create: (_) => HistoricoViewModel(atendimentos)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telecom ISP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashView(),
        '/login': (_) => const LoginView(),
        '/home': (_) => const HomeView(),
        '/atendimento': (_) => const AtendimentoView(),
        '/historico': (_) => const HistoricoView(),
        '/detalhes': (_) => const AtendimentoView(),
      },
    );
  }
}
