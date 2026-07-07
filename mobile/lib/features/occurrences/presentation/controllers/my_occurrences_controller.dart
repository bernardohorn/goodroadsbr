import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/paginated_occurrences.dart';
import 'occurrences_providers.dart';

/// Estado paginado de "Minhas ocorrências" (aba 1 do Histórico). Mantido
/// separado do provider "recentes" da Home porque aqui precisamos de
/// paginação incremental (`loadMore`), enquanto a Home so quer os 3 mais
/// recentes.
class MyOccurrencesController extends AsyncNotifier<PaginatedOccurrences> {
  int _page = 1;
  String? _statusFilter;

  @override
  Future<PaginatedOccurrences> build() => _fetch(page: 1);

  Future<PaginatedOccurrences> _fetch({required int page}) async {
    final result = await ref.read(listMyOccurrencesUseCaseProvider)(page: page, status: _statusFilter);
    return result.fold((failure) => throw failure, (data) => data);
  }

  Future<void> refresh() async {
    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: 1));
  }

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status;
    await refresh();
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage) return;

    final next = await _fetch(page: _page + 1);
    _page += 1;
    state = AsyncData(
      PaginatedOccurrences(
        items: [...current.items, ...next.items],
        total: next.total,
        page: next.page,
        pageSize: next.pageSize,
      ),
    );
  }
}

final myOccurrencesControllerProvider =
    AsyncNotifierProvider<MyOccurrencesController, PaginatedOccurrences>(MyOccurrencesController.new);
