import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';

/// Estado de sessao do app inteiro. `null` = deslogado, `User` = logado.
/// O `go_router` (ver core/routing/app_router.dart) observa este provider
/// para decidir entre a pilha de telas publicas (login/cadastro) e a
/// pilha autenticada (home/mapa/historico/perfil).
class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Se o backend invalidar a sessao (refresh token expirado/reusado —
    // ver core/network/dio_client.dart), este listener desloga o usuario
    // localmente sem que o `core` precise conhecer esta feature.
    ref.listen(sessionExpiredProvider, (previous, next) {
      if (previous != null && previous != next) {
        state = const AsyncData(null);
      }
    });

    final user = await ref.read(restoreSessionUseCaseProvider)();
    if (user != null) unawaited(_registerPushToken());
    return user;
  }

  Future<Result<User>> login({required String email, required String password}) async {
    final result = await ref.read(loginUseCaseProvider)(email: email, password: password);
    result.fold((_) {}, (user) {
      state = AsyncData(user);
      unawaited(_registerPushToken());
    });
    return result;
  }

  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    String? cpf,
    DateTime? birthDate,
    String? phone,
  }) async {
    final result = await ref.read(registerUseCaseProvider)(
      name: name,
      email: email,
      password: password,
      cpf: cpf,
      birthDate: birthDate,
      phone: phone,
    );
    result.fold((_) {}, (user) {
      state = AsyncData(user);
      unawaited(_registerPushToken());
    });
    return result;
  }

  Future<void> logout() async {
    await _unregisterPushToken();
    await ref.read(logoutUseCaseProvider)();
    state = const AsyncData(null);
  }

  /// Envia o token FCM do device para o backend associar ao usuario logado
  /// (ver `PUSH_DRIVER=fcm` em backend/.env.example). Falha em obter o
  /// token (ex.: Firebase nao configurado neste build — ver
  /// mobile/README.md) nunca deve impedir o login: push e um extra.
  Future<void> _registerPushToken() async {
    try {
      final token = await ref.read(pushRegistrationServiceProvider).getToken();
      if (token != null) {
        await ref.read(deviceRegistrationRepositoryProvider).register(token);
      }
    } catch (_) {
      // Firebase pode nao estar configurado neste build (flutterfire
      // configure nao rodado) — degrada graciosamente sem push.
    }
  }

  Future<void> _unregisterPushToken() async {
    try {
      final token = await ref.read(pushRegistrationServiceProvider).getToken();
      if (token != null) {
        await ref.read(deviceRegistrationRepositoryProvider).unregister(token);
      }
    } catch (_) {
      // Idem.
    }
  }

  Future<Result<User>> updateProfile({String? name, String? phone, String? avatarUrl}) async {
    final result = await ref.read(updateProfileUseCaseProvider)(name: name, phone: phone, avatarUrl: avatarUrl);
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);
