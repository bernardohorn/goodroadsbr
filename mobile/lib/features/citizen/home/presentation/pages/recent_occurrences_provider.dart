import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../occurrences/domain/entities/occurrence.dart';
import '../../../../occurrences/presentation/controllers/occurrences_providers.dart';

/// Ultimas 3 ocorrencias do cidadao, para a secao "Ocorrências recentes" da
/// Home. `autoDispose` porque so faz sentido enquanto a Home esta visivel.
final recentOccurrencesProvider = FutureProvider.autoDispose<List<Occurrence>>((ref) async {
  final result = await ref.watch(listMyOccurrencesUseCaseProvider)(page: 1);
  return result.fold((failure) => throw failure, (page) => page.items.take(3).toList());
});
