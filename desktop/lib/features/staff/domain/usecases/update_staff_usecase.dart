import '../../../../core/error/result.dart';
import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class UpdateStaffUseCase {
  const UpdateStaffUseCase(this._repo);
  final StaffRepository _repo;

  Future<Result<StaffMember>> call({required String id, String? name, String? phone, String? role, bool? active}) {
    return _repo.update(id: id, name: name, phone: phone, role: role, active: active);
  }
}
