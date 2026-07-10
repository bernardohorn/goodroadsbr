import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/paginated_citizens.dart';
import 'citizens_providers.dart';

/// Estado paginado da secao "Cidadaos" na tela "Usuarios". Mesmo padrao de
/// paginas explicitas do OccurrencesListController (nao scroll infinito),
/// ja que a tela usa uma DataTable.
class CitizensListController extends AsyncNotifier<PaginatedCitizens> {
  int _page = 1;
  String? _search;

  int get page => _page;
  String? get search => _search;

  @override
  Future<PaginatedCitizens> build() => _fetch();

  Future<PaginatedCitizens> _fetch() async {
    final result = await ref.read(listCitizensUseCaseProvider)(page: _page, search: _search);
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

  Future<void> setSearch(String? search) async {
    _search = (search == null || search.isEmpty) ? null : search;
    _page = 1;
    await refresh();
  }
}

final citizensListControllerProvider =
    AsyncNotifierProvider<CitizensListController, PaginatedCitizens>(CitizensListController.new);
