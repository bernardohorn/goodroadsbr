import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

final authRemoteDataSourceProvider = Provider((ref) => AuthRemoteDataSource(ref.watch(dioProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
});

final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final registerUseCaseProvider = Provider((ref) => RegisterUseCase(ref.watch(authRepositoryProvider)));
final logoutUseCaseProvider = Provider((ref) => LogoutUseCase(ref.watch(authRepositoryProvider)));
final restoreSessionUseCaseProvider = Provider((ref) => RestoreSessionUseCase(ref.watch(authRepositoryProvider)));
final forgotPasswordUseCaseProvider = Provider((ref) => ForgotPasswordUseCase(ref.watch(authRepositoryProvider)));
final updateProfileUseCaseProvider = Provider((ref) => UpdateProfileUseCase(ref.watch(authRepositoryProvider)));
