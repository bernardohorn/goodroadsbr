import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/staff_remote_data_source.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../domain/usecases/create_staff_usecase.dart';
import '../../domain/usecases/list_staff_usecase.dart';
import '../../domain/usecases/update_staff_usecase.dart';

final staffRemoteDataSourceProvider = Provider((ref) => StaffRemoteDataSource(ref.watch(dioProvider)));

final staffRepositoryProvider = Provider<StaffRepository>((ref) => StaffRepositoryImpl(ref.watch(staffRemoteDataSourceProvider)));

final listStaffUseCaseProvider = Provider((ref) => ListStaffUseCase(ref.watch(staffRepositoryProvider)));
final createStaffUseCaseProvider = Provider((ref) => CreateStaffUseCase(ref.watch(staffRepositoryProvider)));
final updateStaffUseCaseProvider = Provider((ref) => UpdateStaffUseCase(ref.watch(staffRepositoryProvider)));

/// Lista completa de funcionarios/admins — reutilizada pela tela "Usuários"
/// e pelo seletor de "Atribuído a" no dialog de atribuição de ocorrências.
final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  final result = await ref.watch(listStaffUseCaseProvider)();
  return result.fold((failure) => throw failure, (staff) => staff);
});
