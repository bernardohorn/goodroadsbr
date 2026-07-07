import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias nao sensiveis (tema, flags de UI da tela Configuracoes).
/// Separado do `SecureStorageService` porque nao ha motivo para pagar o
/// custo de criptografia do Credential Manager para dados que nao sao
/// segredos.
class LocalPreferencesService {
  LocalPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'goodroads.themeMode';
  static const _desktopNotificationsKey = 'goodroads.desktopNotifications';

  String? getThemeMode() => _prefs.getString(_themeModeKey);
  Future<void> setThemeMode(String value) => _prefs.setString(_themeModeKey, value);

  bool getDesktopNotificationsEnabled() => _prefs.getBool(_desktopNotificationsKey) ?? true;
  Future<void> setDesktopNotificationsEnabled(bool value) => _prefs.setBool(_desktopNotificationsKey, value);
}
