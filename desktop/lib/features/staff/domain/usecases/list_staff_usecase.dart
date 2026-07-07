import '../../../../core/error/result.dart';
import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class ListStaffUseCase {
  const ListStaffUseCase(this._repo);
  final StaffRepository _repo;

  Future<Result<List<StaffMember>>> call({String? search}) => _repo.list(search: search);
}
