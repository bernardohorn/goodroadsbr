import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_data_source.dart';

class StaffRepositoryImpl implements StaffRepository {
  const StaffRepositoryImpl(this._remote);
  final StaffRemoteDataSource _remote;

  @override
  Future<Result<List<StaffMember>>> list({String? search}) async {
    try {
      return Result.success(await _remote.list(search: search));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<StaffMember>> create({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    try {
      return Result.success(await _remote.create(name: name, email: email, password: password, role: role, phone: phone));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<StaffMember>> update({required String id, String? name, String? phone, String? role, bool? active}) async {
    try {
      return Result.success(await _remote.update(id: id, name: name, phone: phone, role: role, active: active));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
