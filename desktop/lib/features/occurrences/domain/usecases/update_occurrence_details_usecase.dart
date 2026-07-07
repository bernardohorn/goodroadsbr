import '../../../../core/error/result.dart';
import '../entities/staff_occurrence.dart';
import '../repositories/occurrences_repository.dart';

class UpdateOccurrenceDetailsUseCase {
  const UpdateOccurrenceDetailsUseCase(this._repo);
  final OccurrencesRepository _repo;

  Future<Result<StaffOccurrence>> call({
    required String id,
    String? categoryId,
    String? priority,
    String? teamId,
    String? assignedToId,
    String? internalNotes,
  }) {
    return _repo.updateDetails(
      id: id,
      categoryId: categoryId,
      priority: priority,
      teamId: teamId,
      assignedToId: assignedToId,
      internalNotes: internalNotes,
    );
  }
}
