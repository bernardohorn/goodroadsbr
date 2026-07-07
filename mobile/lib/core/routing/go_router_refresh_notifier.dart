import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Ponte entre o `AsyncNotifier` de autenticacao (Riverpod) e o
/// `Listenable` que o `go_router` espera em `refreshListenable`. Sem isso,
/// o router so reavaliaria `redirect` em uma navegacao explicita, nao
/// quando o estado de login muda "por baixo" (ex.: logout automatico por
/// sessao expirada).
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AsyncValue>(authControllerProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
