import '../../../../core/error/result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<User>> login({required String email, required String password});

  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    String? cpf,
    DateTime? birthDate,
    String? phone,
  });

  Future<void> logout();

  Future<Result<void>> forgotPassword(String email);

  Future<Result<void>> resetPassword({required String token, required String newPassword});

  /// Retorna o usuario autenticado se houver uma sessao valida (token salvo
  /// no secure storage + confirmacao no backend), ou `null` caso contrario.
  /// Usado no bootstrap do app para decidir a rota inicial.
  Future<User?> restoreSession();

  Future<Result<User>> updateProfile({String? name, String? phone, String? avatarUrl});
}
