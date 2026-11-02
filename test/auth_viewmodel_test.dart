import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';
import 'package:projeto_telecom/viewModel/auth_viewmodel.dart';

class _AuthRepositoryTeste extends AuthRepository {
  final bool resultado;
  String? senhaRecebida;

  _AuthRepositoryTeste(this.resultado);

  @override
  Future<bool> login(String email, String senhaAssinada) async {
    senhaRecebida = senhaAssinada;
    return resultado;
  }
}

void main() {
  test('login rejeitado não é tratado como sucesso', () async {
    final repositorio = _AuthRepositoryTeste(false);
    final viewModel = AuthViewModel(repositorio);

    final sucesso = await viewModel.fazerLogin('teste@exemplo.com', 'senha');

    expect(sucesso, isFalse);
    expect(viewModel.errorMessage, isNotNull);
    expect(viewModel.isLoading, isFalse);
  });

  test('login envia HMAC-SHA256 em vez da senha original', () async {
    final repositorio = _AuthRepositoryTeste(true);
    final viewModel = AuthViewModel(repositorio);

    final sucesso = await viewModel.fazerLogin('teste@exemplo.com', 'senha');

    expect(sucesso, isTrue);
    expect(repositorio.senhaRecebida, hasLength(64));
    expect(repositorio.senhaRecebida, isNot('senha'));
    expect(viewModel.isLoading, isFalse);
  });
}
