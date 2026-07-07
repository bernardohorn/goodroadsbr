import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/app.dart';
import 'package:goodroads_desktop/core/di/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `flutter_secure_storage` fala com o Credential Manager via canal de
/// plataforma, que nao existe em `flutter test` (roda em Dart puro, sem
/// Windows real). Sem esse fake, a leitura do token nunca resolve, o
/// `AuthController` fica preso em loading para sempre e o `SplashPage`
/// (com seu `CircularProgressIndicator` indeterminado) nunca sai de tela —
/// e e exatamente isso que faz `pumpAndSettle` estourar o timeout.
class _InMemorySecureStorage extends FlutterSecureStoragePlatform {
  final _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async => _values[key];

  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async =>
      _values.containsKey(key);

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    _values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async => Map.of(_values);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _values.clear();
  }
}

void main() {
  testWidgets('StaffApp inicia na tela de login quando nao ha sessao salva', (tester) async {
    FlutterSecureStoragePlatform.instance = _InMemorySecureStorage();
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
        child: const StaffApp(),
      ),
    );

    // Sem token salvo, o AuthController resolve `restoreSession()` como
    // `null` (nao ha chamada de rede real neste ambiente de teste) e o
    // router redireciona da splash para o login.
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
