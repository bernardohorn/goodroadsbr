import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../categories/presentation/controllers/categories_providers.dart';
import '../../domain/entities/occurrence_filters.dart';
import '../controllers/occurrences_list_controller.dart';

const _statusOptions = {'PENDENTE': 'Pendente', 'EM_ANDAMENTO': 'Em andamento', 'RESOLVIDA': 'Resolvida', 'CANCELADA': 'Cancelada'};
const _priorityOptions = {'BAIXA': 'Baixa', 'MEDIA': 'Média', 'ALTA': 'Alta', 'URGENTE': 'Urgente'};

/// Tela 3/10 do desktop: listagem de todas as ocorrencias da prefeitura,
/// com busca/filtros/ordenacao/paginacao (ver
/// docs/ARQUITETURA_GOODROADS.md, secao 7.5).
class OccurrencesListPage extends ConsumerStatefulWidget {
  const OccurrencesListPage({super.key});

  @override
  ConsumerState<OccurrencesListPage> createState() => _OccurrencesListPageState();
}

class _OccurrencesListPageState extends ConsumerState<OccurrencesListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters(OccurrenceFilters Function(OccurrenceFilters) update) {
    final controller = ref.read(occurrencesListControllerProvider.notifier);
    controller.setFilters(update(controller.filters));
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(occurrencesListControllerProvider);
    final controller = ref.read(occurrencesListControllerProvider.notifier);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Ocorrências',
              subtitle: 'Todas as ocorrências registradas pelos cidadãos.',
              action: IconButton(icon: const Icon(Icons.refresh), onPressed: controller.refresh),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por protocolo, descrição ou endereço',
                    ),
                    onSubmitted: (value) => _applyFilters((f) => f.copyWith(search: value)),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    initialValue: controller.filters.status,
                    decoration: const InputDecoration(isDense: true, labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      for (final entry in _statusOptions.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                    ],
                    onChanged: (value) => _applyFilters(
                      (f) => value == null ? f.copyWith(clearStatus: true) : f.copyWith(status: value),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    isDense: true,
                    initialValue: controller.filters.priority,
                    decoration: const InputDecoration(isDense: true, labelText: 'Prioridade'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      for (final entry in _priorityOptions.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                    ],
                    onChanged: (value) => _applyFilters(
                      (f) => value == null ? f.copyWith(clearPriority: true) : f.copyWith(priority: value),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: categoriesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (categories) => DropdownButtonFormField<String>(
                      isDense: true,
                      initialValue: controller.filters.categoryId,
                      decoration: const InputDecoration(isDense: true, labelText: 'Categoria'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (value) => _applyFilters(
                        (f) => value == null ? f.copyWith(clearCategoryId: true) : f.copyWith(categoryId: value),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: listAsync.when(
                loading: () => const Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow(), SkeletonRow()]),
                error: (error, _) => Center(child: Text('Não foi possível carregar as ocorrências: $error')),
                data: (page) {
                  if (page.items.isEmpty) {
                    return const EmptyState(icon: Icons.inbox_outlined, title: 'Nenhuma ocorrência encontrada');
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Protocolo')),
                                DataColumn(label: Text('Descrição')),
                                DataColumn(label: Text('Categoria')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Prioridade')),
                                DataColumn(label: Text('Registrada em')),
                              ],
                              rows: [
                                for (final o in page.items)
                                  DataRow(
                                    onSelectChanged: (_) => context.push(AppRoutes.occurrenceDetailsPath(o.id)),
                                    cells: [
                                      DataCell(Text(o.protocolNumber)),
                                      DataCell(SizedBox(width: 260, child: Text(o.description, maxLines: 1, overflow: TextOverflow.ellipsis))),
                                      DataCell(Text(o.categoryName ?? '—')),
                                      DataCell(StatusChip(status: o.status)),
                                      DataCell(PriorityChip(priority: o.priority)),
                                      DataCell(Text(dateFormat.format(o.createdAt))),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${page.total} ocorrência(s) · página ${page.page} de ${page.totalPages}'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: page.page > 1 ? () => controller.setPage(page.page - 1) : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: page.hasNextPage ? () => controller.setPage(page.page + 1) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
