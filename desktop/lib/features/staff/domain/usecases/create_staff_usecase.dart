import '../../../../core/error/result.dart';
import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class CreateStaffUseCase {
  const CreateStaffUseCase(this._repo);
  final StaffRepository _repo;

  Future<Result<StaffMember>> call({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) {
    return _repo.create(name: name, email: email, password: password, role: role, phone: phone);
  }
}
