import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/occurrence_status_history_entry.dart';
import '../../domain/entities/staff_occurrence.dart';
import 'occurrences_providers.dart';

final occurrenceDetailsProvider = FutureProvider.autoDispose.family<StaffOccurrence, String>((ref, id) async {
  final result = await ref.watch(getOccurrenceUseCaseProvider)(id);
  return result.fold((failure) => throw failure, (occurrence) => occurrence);
});

final occurrenceHistoryProvider =
    FutureProvider.autoDispose.family<List<OccurrenceStatusHistoryEntry>, String>((ref, id) async {
  final result = await ref.watch(getOccurrenceHistoryUseCaseProvider)(id);
  return result.fold((failure) => throw failure, (history) => history);
});
