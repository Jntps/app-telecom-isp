import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewModel/auth_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _realizarLogin() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Ocultar teclado após clicar em entrar
      FocusScope.of(context).unfocus();

      // Chama a ViewModel para assinar e enviar os dados
      final sucesso = await authViewModel.fazerLogin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (sucesso) {
        if (!mounted) return;
        // Navega para a Home (substitui a rota atual para não voltar ao login)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        // Mostra o erro (ex: credenciais incorretas) num SnackBar vermelho
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'Erro ao fazer login'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escutamos o estado da ViewModel para mostrar a rodinha de carregamento
    final isLoading = context.watch<AuthViewModel>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logótipo / Ícone da App
                    const Icon(Icons.cell_tower, size: 64, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'Telecom ISP',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),