import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias nao sensiveis (tema, flags de UI). Separado do
/// `SecureStorageService` porque nao ha motivo para pagar o custo de
/// criptografia do Keychain/Keystore para dados que nao sao segredos.
class LocalPreferencesService {
  LocalPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'goodroads.themeMode';

  String? getThemeMode() => _prefs.getString(_themeModeKey);

  Future<void> setThemeMode(String value) => _prefs.setString(_themeModeKey, value);
}
