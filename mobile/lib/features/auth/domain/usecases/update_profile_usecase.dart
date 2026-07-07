import '../../../../core/error/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({String? name, String? phone, String? avatarUrl}) {
    return _repository.updateProfile(name: name, phone: phone, avatarUrl: avatarUrl);
  }
}
