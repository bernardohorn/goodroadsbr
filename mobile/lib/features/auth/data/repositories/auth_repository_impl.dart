import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorageService storage,
  })  : _remote = remoteDataSource,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  @override
  Future<Result<User>> login({required String email, required String password}) async {
    try {
      final response = await _remote.login(email: email, password: password);
      await _storage.saveTokens(accessToken: response.accessToken, refreshToken: response.refreshToken);
      return Result.success(response.user);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<User>> register({
    required String name,
    required String email,
    required String password,
    String? cpf,
    DateTime? birthDate,
    String? phone,
  }) async {
    try {
      final response = await _remote.register(
        name: name,
        email: email,
        password: password,
        cpf: cpf,
        birthDate: birthDate,
        phone: phone,
      );
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
        // Mesmo se a chamada falhar (ex.: sem internet), o storage local e
        // limpo abaixo — o usuario nao deve ficar "preso" logado no
        // dispositivo por causa de uma falha de rede no logout.
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
  Future<User?> restoreSession() async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken == null) return null;

    try {
      return await _remote.fetchCurrentUser();
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  @override
  Future<Result<User>> updateProfile({String? name, String? phone, String? avatarUrl}) async {
    try {
      final user = await _remote.updateProfile(name: name, phone: phone, avatarUrl: avatarUrl);
      return Result.success(user);
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
