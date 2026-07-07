import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<void>> call(String email) => _repo.forgotPassword(email);
}
