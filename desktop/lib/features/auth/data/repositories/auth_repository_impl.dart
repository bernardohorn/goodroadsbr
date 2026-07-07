import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/staff_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource, required SecureStorageService storage})
      : _remote = remoteDataSource,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  @override
  Future<Result<StaffUser>> login({required String email, required String password}) async {
    try {
      final response = await _remote.login(email: email, password: password);

      // O endpoint de login e compartilhado com o app mobile (mesmo
      // backend); um cidadao poderia digitar credenciais validas aqui. O
      // RBAC do backend ja bloqueia essa conta em qualquer rota de
      // funcionario, mas rejeitamos no cliente logo apos o login para dar
      // uma mensagem clara em vez de uma tela cheia de erros 403.
      if (response.user.role != 'FUNCIONARIO' && response.user.role != 'ADMIN') {
        await _storage.clear();
        return const Result.failure(
          UnauthorizedFailure('Esta conta nao tem acesso ao painel administrativo.'),
        );
      }

      await _storage.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken);
      return Result.success(response.user);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _remote.logout(refreshToken);
      } catch (_) {
        // Mesmo se a chamada falhar, o storage local e limpo abaixo — o
        // usuario nao deve ficar "preso" logado por causa de uma falha de
        // rede no logout.
      }
    }
    await _storage.clear();
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Result.success(null);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<void>> resetPassword({required String token, required String newPassword}) async {
    try {
      await _remote.resetPassword(token: token, newPassword: newPassword);
      return const Result.success(null);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<StaffUser?> restoreSession() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) return null;

    try {
      final user = await _remote.fetchCurrentUser();
      if (user.role != 'FUNCIONARIO' && user.role != 'ADMIN') {
        await _storage.clear();
        return null;
      }
      return user;
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<Result<StaffUser>> updateProfile({String? name, String? phone}) async {
    try {
      final user = await _remote.updateProfile(name: name, phone: phone);
      return Result.success(user);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
