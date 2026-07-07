import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../domain/entities/occurrence.dart';

class OccurrenceCard extends StatelessWidget {
  const OccurrenceCard({super.key, required this.occurrence});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.occurrenceDetailsPath(occurrence.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: occurrence.coverPhotoUrl.isEmpty
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.outline),
                        )
                      : CachedNetworkImage(
                          imageUrl: occurrence.coverPhotoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: theme.colorScheme.surfaceContainerHighest),
                          errorWidget: (_, _, _) => Container(color: theme.colorScheme.surfaceContainerHighest),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.categoryName ?? 'Ocorrência registrada',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      occurrence.address ?? occurrence.protocolNumber,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(occurrence.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 8),
                    StatusChip(status: occurrence.status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
