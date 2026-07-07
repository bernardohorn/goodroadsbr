import '../../../../core/error/result.dart';
import '../entities/staff_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<StaffUser>> call({required String email, required String password}) {
    return _repo.login(email: email, password: password);
  }
}
