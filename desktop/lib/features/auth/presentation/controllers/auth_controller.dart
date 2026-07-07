import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/staff_user.dart';
import 'auth_providers.dart';

/// Estado de sessao do app inteiro. `null` = deslogado, `StaffUser` =
/// logado. O `go_router` (ver core/routing/app_router.dart) observa este
/// provider para decidir entre a tela de login e a barra lateral
/// autenticada.
class AuthController extends AsyncNotifier<StaffUser?> {
  @override
  Future<StaffUser?> build() async {
    // Se o backend invalidar a sessao (refresh token expirado/reusado —
    // ver core/network/dio_client.dart), este listener desloga o usuario
    // localmente sem que o `core` precise conhecer esta feature.
    ref.listen(sessionExpiredProvider, (previous, next) {
      if (previous != null && previous != next) {
        state = const AsyncData(null);
      }
    });

    return ref.read(restoreSessionUseCaseProvider)();
  }

  Future<Result<StaffUser>> login({required String email, required String password}) async {
    final result = await ref.read(loginUseCaseProvider)(email: email, password: password);
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }

  Future<void> logout() async {
    await ref.read(logoutUseCaseProvider)();
    state = const AsyncData(null);
  }

  Future<Result<StaffUser>> updateProfile({String? name, String? phone}) async {
    final result = await ref.read(updateProfileUseCaseProvider)(name: name, phone: phone);
    result.fold((_) {}, (user) => state = AsyncData(user));
    return result;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, StaffUser?>(AuthController.new);
