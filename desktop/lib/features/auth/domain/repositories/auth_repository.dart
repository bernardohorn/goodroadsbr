import '../../../../core/error/result.dart';
import '../entities/staff_user.dart';

abstract class AuthRepository {
  Future<Result<StaffUser>> login({required String email, required String password});
  Future<void> logout();
  Future<StaffUser?> restoreSession();
  Future<Result<void>> forgotPassword(String email);
  Future<Result<void>> resetPassword({required String token, required String newPassword});
  Future<Result<StaffUser>> updateProfile({String? name, String? phone});
}
