import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<void>> call({required String token, required String newPassword}) {
    return _repo.resetPassword(token: token, newPassword: newPassword);
  }
}
