import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/occurrences_remote_data_source.dart';
import '../../data/repositories/occurrences_repository_impl.dart';
import '../../domain/repositories/occurrences_repository.dart';
import '../../domain/usecases/create_occurrence_usecase.dart';
import '../../domain/usecases/get_occurrence_history_usecase.dart';
import '../../domain/usecases/get_occurrence_usecase.dart';
import '../../domain/usecases/list_categories_usecase.dart';
import '../../domain/usecases/list_my_occurrences_usecase.dart';

final occurrencesRemoteDataSourceProvider = Provider((ref) => OccurrencesRemoteDataSource(ref.watch(dioProvider)));

final occurrencesRepositoryProvider = Provider<OccurrencesRepository>((ref) {
  return OccurrencesRepositoryImpl(ref.watch(occurrencesRemoteDataSourceProvider));
});

final createOccurrenceUseCaseProvider = Provider((ref) => CreateOccurrenceUseCase(ref.watch(occurrencesRepositoryProvider)));
final listMyOccurrencesUseCaseProvider = Provider((ref) => ListMyOccurrencesUseCase(ref.watch(occurrencesRepositoryProvider)));
final getOccurrenceUseCaseProvider = Provider((ref) => GetOccurrenceUseCase(ref.watch(occurrencesRepositoryProvider)));
final getOccurrenceHistoryUseCaseProvider = Provider((ref) => GetOccurrenceHistoryUseCase(ref.watch(occurrencesRepositoryProvider)));
final listCategoriesUseCaseProvider = Provider((ref) => ListCategoriesUseCase(ref.watch(occurrencesRepositoryProvider)));
