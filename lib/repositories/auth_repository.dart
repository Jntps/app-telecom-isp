import '../datasources/remote_datasource.dart';
import '../datasources/token_store.dart';

class AuthRepository {
  final RemoteDatasource remoto;
  final TokenStore tokens;

  AuthRepository({RemoteDatasource? remoto, TokenStore? tokens})
      : remoto = remoto ?? RemoteDatasource(),
        tokens = tokens ?? const SecureTokenStore();

  // A ViewModel calcula HMAC-SHA256 antes desta chamada.
  Future<bool> login(String email, String senhaHmac) async {
    final resultado = await remoto.login(email, senhaHmac);
    await tokens.salvar(resultado.token);
    return true;
  }

  Future<String?> getToken() => tokens.ler();
  Future<void> logout() => tokens.apagar();
}