import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/citizens_remote_data_source.dart';
import '../../data/repositories/citizens_repository_impl.dart';
import '../../domain/repositories/citizens_repository.dart';
import '../../domain/usecases/list_citizens_usecase.dart';
import '../../domain/usecases/update_citizen_status_usecase.dart';

final citizensRemoteDataSourceProvider = Provider((ref) => CitizensRemoteDataSource(ref.watch(dioProvider)));

final citizensRepositoryProvider = Provider<CitizensRepository>((ref) {
  return CitizensRepositoryImpl(ref.watch(citizensRemoteDataSourceProvider));
});

final listCitizensUseCaseProvider = Provider((ref) => ListCitizensUseCase(ref.watch(citizensRepositoryProvider)));
final updateCitizenStatusUseCaseProvider =
    Provider((ref) => UpdateCitizenStatusUseCase(ref.watch(citizensRepositoryProvider)));
