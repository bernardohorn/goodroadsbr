import '../../../../core/error/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({
    required String name,
    required String email,
    required String password,
    String? cpf,
    DateTime? birthDate,
    String? phone,
  }) {
    return _repository.register(
      name: name,
      email: email,
      password: password,
      cpf: cpf,
      birthDate: birthDate,
      phone: phone,
    );
  }
}
