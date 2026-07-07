import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/citizen/history/presentation/pages/history_page.dart';
import '../../features/citizen/home/presentation/pages/home_page.dart';
import '../../features/citizen/profile/presentation/pages/profile_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/occurrences/presentation/pages/occurrence_details_page.dart';
import '../../features/occurrences/presentation/pages/register_occurrence_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'go_router_refresh_notifier.dart';
import 'splash_page.dart';

/// Configuracao central de navegacao. O `redirect` e a unica fonte de
/// verdade sobre quem pode acessar o que — nenhuma tela precisa checar
/// "estou logado?" manualmente antes de se construir (RBAC no frontend,
/// ver docs/ARQUITETURA_GOODROADS.md, secao 4.1).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isBootstrapping = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.login || location == AppRoutes.register;
      final isSplash = location == AppRoutes.splash;

      if (isBootstrapping) return isSplash ? null : AppRoutes.splash;
      if (isSplash) return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterPage()),
      GoRoute(path: AppRoutes.registerOccurrence, builder: (context, state) => const RegisterOccurrencePage()),
      GoRoute(
        path: AppRoutes.occurrenceDetails,
        builder: (context, state) => OccurrenceDetailsPage(occurrenceId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.map, builder: (context, state) => const MapPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.history, builder: (context, state) => const HistoryPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfilePage())]),
        ],
      ),
    ],
  );
});
