import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projeto_telecom/view/detalhes_view.dart';

// Imports de Autenticação
import 'repositories/auth_repository.dart';
import 'viewModel/auth_viewmodel.dart';

// Imports de Chamados
import 'repositories/chamados_repository.dart';
import 'viewModel/chamados_viewmodel.dart';

// Imports das Views
import 'view/splash_view.dart';
import 'view/login_view.dart';
import 'view/home_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Provider de Autenticação
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepository()),
        ),
        // Novo Provider de Chamados (Injetado aqui)
        ChangeNotifierProvider(
          create: (_) => ChamadosViewModel(ChamadosRepository(), AuthRepository()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telecom ISP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      initialRoute: '/splash', // Arranca sempre pela verificação de sessão
      routes: {
        '/splash': (context) => const SplashView(),
        '/login': (context) => const LoginView(),
        '/home': (context) => const HomeView(),
        '/detalhes': (context) => const DetalhesView(), // <-- ADICIONA ESTA LINHA
      },
    );
  }
}