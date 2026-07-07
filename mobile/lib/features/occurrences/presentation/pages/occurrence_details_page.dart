import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../map/presentation/controllers/map_providers.dart';
import '../controllers/occurrence_details_providers.dart';
import '../widgets/status_timeline.dart';

String _statusLabel(String status) => switch (status) {
      'PENDENTE' => 'Pendente',
      'EM_ANDAMENTO' => 'Em andamento',
      'RESOLVIDA' => 'Resolvida',
      'CANCELADA' => 'Cancelada',
      _ => status,
    };

class OccurrenceDetailsPage extends ConsumerWidget {
  const OccurrenceDetailsPage({super.key, required this.occurrenceId});

  final String occurrenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrenceAsync = ref.watch(occurrenceDetailsProvider(occurrenceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da ocorrência')),
      body: occurrenceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error is Failure ? error.message : 'Não foi possível carregar esta ocorrência.'),
          ),
        ),
        data: (occurrence) {
          final theme = Theme.of(context);
          final historyAsync = ref.watch(occurrenceHistoryProvider(occurrenceId));

          return ListView(
            children: [
              if (occurrence.photos.isNotEmpty)
                SizedBox(
                  height: 240,
                  child: PageView(
                    children: [
                      for (final photo in occurrence.photos)
                        CachedNetworkImage(
                          imageUrl: photo.url,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: theme.colorScheme.surfaceContainerHighest),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusChip(status: occurrence.status),
                        Text(
                          DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(occurrence.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Protocolo ${occurrence.protocolNumber}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Descrição', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(occurrence.description, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    Text('Localização', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    if (occurrence.address != null) Text(occurrence.address!, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 160,
                        child: IgnorePointer(
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(occurrence.latitude, occurrence.longitude),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                            ),
                            children: [
                              ref.watch(mapProviderContractProvider).buildTileLayer(),
                              MarkerLayer(markers: [
                                Marker(
                                  point: LatLng(occurrence.latitude, occurrence.longitude),
                                  width: 36,
                                  height: 36,
                                  child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 36),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A localização é aproximada e pode variar em alguns metros.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 24),
                    Text('Status da ocorrência', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 12),
                    StatusTimeline(currentStatus: occurrence.status),
                    const SizedBox(height: 24),
                    Text('Histórico', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    historyAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (entries) => Column(
                        children: [
                          for (final entry in entries)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.circle, size: 10),
                              title: Text(_statusLabel(entry.newStatus)),
                              subtitle: Text(
                                '${entry.changedByName} · ${DateFormat('dd/MM/yyyy HH:mm').format(entry.changedAt)}'
                                '${entry.note != null ? '\n${entry.note}' : ''}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
