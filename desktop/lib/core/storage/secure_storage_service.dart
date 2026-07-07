import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encapsula o acesso ao Credential Manager (Windows) / Keychain (macOS) /
/// Secret Service (Linux) para os tokens de autenticacao. Nenhuma outra
/// parte do app deve importar `flutter_secure_storage` diretamente — isso
/// mantem a troca de mecanismo de armazenamento (caso necessario) restrita
/// a esta classe.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'goodroads.accessToken';
  static const _refreshTokenKey = 'goodroads.refreshToken';

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
