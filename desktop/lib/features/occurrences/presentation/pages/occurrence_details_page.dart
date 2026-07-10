import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/map/osm_map_provider.dart';
import '../../../../core/utils/cpf_formatter.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/occurrence_status_history_entry.dart';
import '../../domain/entities/staff_occurrence.dart';
import '../controllers/occurrence_details_providers.dart';
import '../widgets/assign_dialog.dart';
import '../widgets/status_timeline.dart';
import '../widgets/status_update_dialog.dart';

final _mapProviderForDetails = Provider((ref) => OsmMapProvider());

String _statusLabel(String status) => const {
      'PENDENTE': 'Pendente',
      'EM_ANDAMENTO': 'Em andamento',
      'RESOLVIDA': 'Resolvida',
      'CANCELADA': 'Cancelada',
    }[status] ??
    status;

/// Tela 4/10 do desktop: detalhes completos de uma ocorrencia, com acoes de
/// staff (mudar status, atribuir/classificar) via dialogs.
class OccurrenceDetailsPage extends ConsumerWidget {
  const OccurrenceDetailsPage({super.key, required this.occurrenceId});

  final String occurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrenceAsync = ref.watch(occurrenceDetailsProvider(occurrenceId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Detalhes da ocorrência'),
      ),
      body: occurrenceAsync.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: Column(children: [SkeletonRow(), SkeletonRow()])),
        error: (error, _) => Center(child: Text('Não foi possível carregar a ocorrência: $error')),
        data: (occurrence) => _DetailsContent(occurrence: occurrence),
      ),
    );
  }
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({required this.occurrence});
  final StaffOccurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final historyAsync = ref.watch(occurrenceHistoryProvider(occurrence.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(occurrence.protocolNumber, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    StatusChip(status: occurrence.status),
                    const SizedBox(width: 8),
                    PriorityChip(priority: occurrence.priority),
                  ],
                ),
                const SizedBox(height: 16),
                StatusTimeline(currentStatus: occurrence.status),
                const SizedBox(height: 24),
                if (occurrence.photos.isNotEmpty) ...[
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: occurrence.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(occurrence.photos[index].url, width: 240, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text('Descrição', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(occurrence.description),
                const SizedBox(height: 24),
                Text('Localização', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (occurrence.address != null) Text(occurrence.address!),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(occurrence.latitude, occurrence.longitude),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                      ),
                      children: [
                        ref.watch(_mapProviderForDetails).buildTileLayer(),
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(occurrence.latitude, occurrence.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Histórico', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                historyAsync.when(
                  loading: () => const SkeletonRow(),
                  error: (error, _) => Text('Não foi possível carregar o histórico: $error'),
                  data: (history) => _HistoryList(entries: history, dateFormat: dateFormat),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Classificação', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Categoria', value: occurrence.categoryName ?? 'Sem categoria'),
                        _InfoRow(label: 'Equipe', value: occurrence.teamName ?? 'Não atribuída'),
                        _InfoRow(label: 'Responsável', value: occurrence.assignedToName ?? 'Não atribuído'),
                        if (occurrence.internalNotes != null && occurrence.internalNotes!.isNotEmpty)
                          _InfoRow(label: 'Observações internas', value: occurrence.internalNotes!),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => AssignDialog.show(context, occurrence: occurrence),
                          icon: const Icon(Icons.assignment_ind_outlined),
                          label: const Text('Atribuir / classificar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cidadão', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Nome', value: occurrence.citizenName ?? '—'),
                        _InfoRow(label: 'CPF', value: formatCpf(occurrence.citizenCpf) ?? '—'),
                        _InfoRow(label: 'E-mail', value: occurrence.citizenEmail ?? '—'),
                        _InfoRow(label: 'Telefone', value: occurrence.citizenPhone ?? '—'),
                        _InfoRow(label: 'Registrada em', value: dateFormat.format(occurrence.createdAt)),
                        if (occurrence.resolvedAt != null)
                          _InfoRow(label: 'Resolvida em', value: dateFormat.format(occurrence.resolvedAt!)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => StatusUpdateDialog.show(context, occurrenceId: occurrence.id, currentStatus: occurrence.status),
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Atualizar status'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
          Text(value),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries, required this.dateFormat});
  final List<OccurrenceStatusHistoryEntry> entries;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Text('Sem histórico registrado.');
    return Card(
      child: Column(
        children: [
          for (final entry in entries)
            ListTile(
              leading: const Icon(Icons.circle, size: 10),
              title: Text(
                entry.previousStatus == null
                    ? 'Ocorrência criada'
                    : '${_statusLabel(entry.previousStatus!)} → ${_statusLabel(entry.newStatus)}',
              ),
              subtitle: Text('${entry.changedByName} · ${dateFormat.format(entry.changedAt)}${entry.note != null ? ' · ${entry.note}' : ''}'),
            ),
        ],
      ),
    );
  }
}
