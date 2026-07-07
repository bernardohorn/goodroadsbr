import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

class _NavEntry {
  const _NavEntry(this.icon, this.selectedIcon, this.label) : adminOnly = false;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool adminOnly;
}

const _entries = [
  _NavEntry(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
  _NavEntry(Icons.report_outlined, Icons.report, 'Ocorrências'),
  _NavEntry(Icons.map_outlined, Icons.map, 'Mapa'),
  _NavEntry(Icons.category_outlined, Icons.category, 'Categorias'),
  _NavEntry(Icons.groups_outlined, Icons.groups, 'Usuários'),
  _NavEntry(Icons.bar_chart_outlined, Icons.bar_chart, 'Relatórios'),
  _NavEntry(Icons.settings_outlined, Icons.settings, 'Configurações'),
];

/// Casca com a barra lateral fixa, compartilhada pelas 7 telas principais
/// do funcionario (Dashboard, Ocorrencias, Mapa, Categorias, Usuarios,
/// Relatorios, Configuracoes) — Perfil vive fora da barra, acessivel pelo
/// avatar no topo (ver docs/ARQUITETURA_GOODROADS.md, secao 7.5).
/// Implementada com `StatefulShellRoute` para preservar o estado de cada
/// aba ao trocar entre elas (ex.: filtros aplicados na lista).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.sidebarBackground,
            child: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_road_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'GoodRoads',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (var i = 0; i < _entries.length; i++) _SidebarItem(
                          entry: _entries[i],
                          selected: navigationShell.currentIndex == i,
                          onTap: () => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  _ProfileTile(name: user?.name ?? '', role: user?.role ?? ''),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.entry, required this.selected, required this.onTap});

  final _NavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(selected ? entry.selectedIcon : entry.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  entry.label,
                  style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.profile),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Carregando…' : name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      role == 'ADMIN' ? 'Administrador' : 'Funcionário',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sair',
                icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
