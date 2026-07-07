import '../entities/staff_user.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repo);
  final AuthRepository _repo;

  Future<StaffUser?> call() => _repo.restoreSession();
}
