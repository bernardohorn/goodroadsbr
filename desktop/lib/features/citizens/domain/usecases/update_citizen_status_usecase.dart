import '../../../../core/error/result.dart';
import '../entities/citizen.dart';
import '../repositories/citizens_repository.dart';

class UpdateCitizenStatusUseCase {
  const UpdateCitizenStatusUseCase(this._repo);
  final CitizensRepository _repo;

  Future<Result<Citizen>> call({required String id, required bool active}) {
    return _repo.updateStatus(id: id, active: active);
  }
}
