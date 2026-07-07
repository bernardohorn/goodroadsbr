import '../../../../core/error/result.dart';
import '../entities/staff_member.dart';

abstract class StaffRepository {
  Future<Result<List<StaffMember>>> list({String? search});
  Future<Result<StaffMember>> create({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  });
  Future<Result<StaffMember>> update({
    required String id,
    String? name,
    String? phone,
    String? role,
    bool? active,
  });
}
