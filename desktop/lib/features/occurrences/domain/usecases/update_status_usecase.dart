import '../../../../core/error/result.dart';
import '../entities/staff_occurrence.dart';
import '../repositories/occurrences_repository.dart';

class UpdateStatusUseCase {
  const UpdateStatusUseCase(this._repo);
  final OccurrencesRepository _repo;

  Future<Result<StaffOccurrence>> call({required String id, required String status, String? note}) {
    return _repo.updateStatus(id: id, status: status, note: note);
  }
}
