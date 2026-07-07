import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import 'occurrences_providers.dart';

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final result = await ref.watch(listCategoriesUseCaseProvider)();
  return result.fold((failure) => throw failure, (categories) => categories);
});
