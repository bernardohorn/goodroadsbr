import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/categories_remote_data_source.dart';
import '../../data/repositories/categories_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/list_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';

final categoriesRemoteDataSourceProvider = Provider((ref) => CategoriesRemoteDataSource(ref.watch(dioProvider)));

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepositoryImpl(ref.watch(categoriesRemoteDataSourceProvider)),
);

final listCategoriesUseCaseProvider = Provider((ref) => ListCategoriesUseCase(ref.watch(categoriesRepositoryProvider)));
final createCategoryUseCaseProvider = Provider((ref) => CreateCategoryUseCase(ref.watch(categoriesRepositoryProvider)));
final updateCategoryUseCaseProvider = Provider((ref) => UpdateCategoryUseCase(ref.watch(categoriesRepositoryProvider)));

/// Lista de categorias reutilizada por varias telas (filtro de Ocorrências,
/// dialog de atribuição, a própria tela Categorias).
final categoriesListProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final result = await ref.watch(listCategoriesUseCaseProvider)();
  return result.fold((failure) => throw failure, (categories) => categories);
});
