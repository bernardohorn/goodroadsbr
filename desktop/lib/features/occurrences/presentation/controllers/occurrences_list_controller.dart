import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/occurrence_filters.dart';
import '../../domain/entities/paginated_occurrences.dart';
import 'occurrences_providers.dart';

/// Estado paginado da tela "Ocorrências". Diferente do app mobile (que usa
/// scroll infinito com `loadMore`), o desktop navega por paginas explicitas
/// (compativel com uma `DataTable` — ver occurrences_list_page.dart).
class OccurrencesListController extends AsyncNotifier<PaginatedOccurrences> {
  int _page = 1;
  OccurrenceFilters _filters = const OccurrenceFilters();

  int get page => _page;
  OccurrenceFilters get filters => _filters;

  @override
  Future<PaginatedOccurrences> build() => _fetch();

  Future<PaginatedOccurrences> _fetch() async {
    final result = await ref.read(listOccurrencesUseCaseProvider)(page: _page, filters: _filters);
    return result.fold((failure) => throw failure, (data) => data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setPage(int page) async {
    _page = page;
    await refresh();
  }

  Future<void> setFilters(OccurrenceFilters filters) async {
    _filters = filters;
    _page = 1;
    await refresh();
  }
}

final occurrencesListControllerProvider =
    AsyncNotifierProvider<OccurrencesListController, PaginatedOccurrences>(OccurrencesListController.new);
