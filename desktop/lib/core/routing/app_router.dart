import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/occurrences/presentation/pages/occurrence_details_page.dart';
import '../../features/occurrences/presentation/pages/occurrences_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/staff/presentation/pages/staff_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'go_router_refresh_notifier.dart';
import 'splash_page.dart';

/// Configuracao central de navegacao. O `redirect` e a unica fonte de
/// verdade sobre quem pode acessar o que — nenhuma tela precisa checar
/// "estou logado?" manualmente antes de se construir (RBAC no frontend,
/// ver docs/ARQUITETURA_GOODROADS.md, secao 4.1). Nao ha rota de cadastro:
/// contas de funcionario sao criadas por um ADMIN na tela "Usuários", nunca
/// por autoatendimento (diferente do app mobile).
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
      final isLogin = location == AppRoutes.login;
      final isSplash = location == AppRoutes.splash;

      if (isBootstrapping) return isSplash ? null : AppRoutes.splash;
      if (isSplash) return isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
      if (!isLoggedIn && !isLogin) return AppRoutes.login;
      if (isLoggedIn && isLogin) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.occurrenceDetails,
        builder: (context, state) => OccurrenceDetailsPage(occurrenceId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.occurrences, builder: (context, state) => const OccurrencesListPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.map, builder: (context, state) => const MapPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.categories, builder: (context, state) => const CategoriesPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.staff, builder: (context, state) => const StaffPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.reports, builder: (context, state) => const ReportsPage())]),
          StatefulShellBranch(routes: [GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsPage())]),
        ],
      ),
    ],
  );
});
