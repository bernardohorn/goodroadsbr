import '../../../../core/error/result.dart';
import '../entities/staff_user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repo);
  final AuthRepository _repo;

  Future<Result<StaffUser>> call({String? name, String? phone}) {
    return _repo.updateProfile(name: name, phone: phone);
  }
}
