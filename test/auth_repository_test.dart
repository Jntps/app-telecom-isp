import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_telecom/data/datasources/remote_datasource.dart';
import 'package:projeto_telecom/data/datasources/token_store.dart';
import 'package:projeto_telecom/data/repositories/auth_repository.dart';

class TokenStoreMemoria implements TokenStore {
  String? token;
  @override
  Future<void> salvar(String valor) async {
    token = valor;
  }
  @override
  Future<String?> ler() async => token;
  @override
  Future<void> apagar() async {
    token = null;
  }
}

class RemoteLoginFake extends RemoteDatasource {
  @override
  Future<LoginResultado> login(String email, String senhaHmac) async =>
      const LoginResultado('token-valido', 1);
}

void main() {
  test('repositório salva e apaga token da sessão', () async {
    final memoria = TokenStoreMemoria();
    final auth = AuthRepository(remoto: RemoteLoginFake(), tokens: memoria);

    expect(await auth.login('teste@exemplo.com', 'hash'), isTrue);
    expect(await auth.getToken(), 'token-valido');

    await auth.logout();
    expect(await auth.getToken(), isNull);
  });
}
