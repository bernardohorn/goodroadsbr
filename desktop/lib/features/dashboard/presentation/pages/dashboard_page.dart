import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../controllers/dashboard_providers.dart';

/// Tela 2/10 do desktop: cards de indicadores + graficos + ocorrencias
/// recentes (ver docs/ARQUITETURA_GOODROADS.md, secao 7.5).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow()]),
        ),
        error: (error, _) => Center(child: Text('Não foi possível carregar o dashboard: $error')),
        data: (result) => result.fold(
          (failure) => Center(child: Text(failure.message)),
          (stats) => _DashboardContent(stats: stats),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.4,
            children: [
              StatCard(label: 'Total de ocorrências', value: '${stats.cards.total}', icon: Icons.report_outlined),
              StatCard(
                label: 'Pendentes',
                value: '${stats.cards.pendentes}',
                icon: Icons.schedule,
                color: AppColors.statusPendente,
              ),
              StatCard(
                label: 'Em andamento',
                value: '${stats.cards.emAndamento}',
                icon: Icons.build_outlined,
                color: AppColors.statusEmAndamento,
              ),
              StatCard(
                label: 'Resolvidas',
                value: '${stats.cards.resolvidas}',
                icon: Icons.check_circle_outline,
                color: AppColors.statusResolvida,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _MonthlyChartCard(data: stats.occurrencesByMonth)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _CategoryBreakdownCard(data: stats.occurrencesByCategory)),
            ],
          ),
          const SizedBox(height: 32),
          const SectionHeader(title: 'Ocorrências recentes'),
          _RecentList(items: stats.recent),
        ],
      ),
    );
  }
}

class _MonthlyChartCard extends StatelessWidget {
  const _MonthlyChartCard({required this.data});
  final List<MonthlyCount> data;

  @override
  Widget build(BuildContext context) {
    final maxTotal = data.fold<int>(1, (max, m) => m.total > max ? m.total : max);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ocorrências por mês', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: (maxTotal * 1.2).ceilToDouble(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const SizedBox.shrink();
                          final parts = data[index].month.split('-');
                          final label = parts.length == 2 ? _monthLabel(parts[1]) : data[index].month;
                          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 11)));
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].total.toDouble(),
                            color: Theme.of(context).colorScheme.primary,
                            width: 22,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthLabel(String mm) {
    const labels = {
      '01': 'Jan', '02': 'Fev', '03': 'Mar', '04': 'Abr', '05': 'Mai', '06': 'Jun',
      '07': 'Jul', '08': 'Ago', '09': 'Set', '10': 'Out', '11': 'Nov', '12': 'Dez',
    };
    return labels[mm] ?? mm;
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.data});
  final List<CategoryCount> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, c) => sum + c.total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por categoria', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (data.isEmpty) const Text('Sem dados ainda.'),
            for (final c in data)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(c.categoryName, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text('${c.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(
                      total == 0 ? '0%' : '${(c.total / total * 100).round()}%',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.items});
  final List<RecentOccurrence> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Nenhuma ocorrência registrada ainda.'));
    }
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      child: Column(
        children: [
          for (final item in items)
            ListTile(
              title: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${item.protocolNumber} · ${item.categoryName ?? 'Sem categoria'} · ${item.citizenName ?? ''}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: item.status),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(item.createdAt), style: const TextStyle(fontSize: 11)),
                ],
              ),
              onTap: () => context.push(AppRoutes.occurrenceDetailsPath(item.id)),
            ),
        ],
      ),
    );
  }
}
