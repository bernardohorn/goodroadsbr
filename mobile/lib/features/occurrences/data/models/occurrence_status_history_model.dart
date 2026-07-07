import '../../domain/entities/occurrence_status_history_entry.dart';

class OccurrenceStatusHistoryModel extends OccurrenceStatusHistoryEntry {
  const OccurrenceStatusHistoryModel({
    super.previousStatus,
    required super.newStatus,
    super.note,
    required super.changedByName,
    required super.changedAt,
  });

  factory OccurrenceStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    final changedBy = json['changedBy'] as Map<String, dynamic>?;
    return OccurrenceStatusHistoryModel(
      previousStatus: json['previousStatus'] as String?,
      newStatus: json['newStatus'] as String,
      note: json['note'] as String?,
      changedByName: changedBy?['name'] as String? ?? 'Equipe da prefeitura',
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }
}
