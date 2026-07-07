import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/offline/offline_providers.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/skeleton_loader.dart';
import '../../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../occurrences/presentation/widgets/occurrence_card.dart';
import 'recent_occurrences_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final recentAsync = ref.watch(recentOccurrencesProvider);
    final pendingAsync = ref.watch(pendingOccurrencesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(recentOccurrencesProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Olá, ${user?.name.split(' ').first ?? 'cidadão'}!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Ajude a melhorar as estradas rurais da nossa região.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
              pendingAsync.maybeWhen(
                data: (pending) => pending.isEmpty ? const SizedBox.shrink() : _PendingSyncBanner(count: pending.length),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              _QuickActionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Registrar ocorrência',
                subtitle: 'Informe um problema na estrada',
                color: theme.colorScheme.primaryContainer,
                onColor: theme.colorScheme.onPrimaryContainer,
                onTap: () => context.push(AppRoutes.registerOccurrence),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.map_outlined,
                title: 'Ver mapa',
                subtitle: 'Veja ocorrências no mapa',
                color: theme.colorScheme.secondaryContainer,
                onColor: theme.colorScheme.onSecondaryContainer,
                onTap: () => context.push(AppRoutes.map),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ocorrências recentes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  TextButton(onPressed: () => context.push(AppRoutes.history), child: const Text('Veja todas')),
                ],
              ),
              recentAsync.when(
                loading: () => Column(children: List.generate(3, (_) => const SkeletonListTile())),
                error: (error, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Não foi possível carregar suas ocorrências',
                  message: error is Failure ? error.message : null,
                ),
                data: (items) => items.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Nenhuma ocorrência registrada ainda',
                        message: 'Toque em "Registrar ocorrência" para começar.',
                      )
                    : Column(children: [for (final item in items) OccurrenceCard(occurrence: item)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de ocorrências salvas offline aguardando envio (Etapa 5). Some
/// sozinho quando a fila esvazia — nao e uma tela nova, so um estado da
/// Home (ver docs/ARQUITETURA_GOODROADS.md, secao 7.4).
class _PendingSyncBanner extends ConsumerStatefulWidget {
  const _PendingSyncBanner({required this.count});
  final int count;

  @override
  ConsumerState<_PendingSyncBanner> createState() => _PendingSyncBannerState();
}

class _PendingSyncBannerState extends ConsumerState<_PendingSyncBanner> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    final result = await ref.read(syncServiceProvider).syncPending();
    ref.invalidate(pendingOccurrencesProvider);
    if (result.synced > 0) ref.invalidate(recentOccurrencesProvider);
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.count} ocorrência(s) aguardando envio',
                  style: TextStyle(color: theme.colorScheme.onTertiaryContainer, fontWeight: FontWeight.w600),
                ),
              ),
              _isSyncing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: _syncNow, child: const Text('Sincronizar')),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: onColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: onColor, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: onColor.withValues(alpha: 0.8), fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: onColor),
            ],
          ),
        ),
      ),
    );
  }
}
