import 'package:equatable/equatable.dart';

class OccurrenceStatusHistoryEntry extends Equatable {
  const OccurrenceStatusHistoryEntry({
    required this.previousStatus,
    required this.newStatus,
    this.note,
    required this.changedByName,
    required this.changedAt,
  });

  final String? previousStatus;
  final String newStatus;
  final String? note;
  final String changedByName;
  final DateTime changedAt;

  @override
  List<Object?> get props => [previousStatus, newStatus, note, changedByName, changedAt];
}
