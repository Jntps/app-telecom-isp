import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStore {
  Future<void> salvar(String token);
  Future<String?> ler();
  Future<void> apagar();
}

class SecureTokenStore implements TokenStore {
  static const _chave = 'auth_token';
  final FlutterSecureStorage storage;
  const SecureTokenStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<void> salvar(String token) =>
      storage.write(key: _chave, value: token);

  @override
  Future<String?> ler() => storage.read(key: _chave);

  @override
  Future<void> apagar() => storage.delete(key: _chave);
}