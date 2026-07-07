import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../network/session_events.dart';
import '../storage/local_preferences_service.dart';
import '../storage/secure_storage_service.dart';

export '../network/session_events.dart' show sessionExpiredProvider;

/// Providers "de infraestrutura" — instancias unicas reaproveitadas pelo
/// resto da aplicacao. Features nunca instanciam `Dio`, `SecureStorageService`
/// etc. diretamente; sempre atraves destes providers.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Sobrescrito em `main.dart` com a instancia real, obtida de forma
/// assincrona antes do `runApp` (Riverpod nao lida bem com providers
/// assincronos para algo consumido de forma sincrona em varios lugares).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider deve ser sobrescrito no bootstrap (main.dart).');
});

final localPreferencesServiceProvider = Provider<LocalPreferencesService>((ref) {
  return LocalPreferencesService(ref.watch(sharedPreferencesProvider));
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    storage: ref.watch(secureStorageServiceProvider),
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).state++,
  );
});

final dioProvider = Provider((ref) => ref.watch(dioClientProvider).dio);
