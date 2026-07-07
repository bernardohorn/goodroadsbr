import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);
  final AuthRepository _repository;

  Future<User?> call() => _repository.restoreSession();
}
