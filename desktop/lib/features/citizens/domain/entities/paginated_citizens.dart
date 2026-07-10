import 'citizen.dart';

class PaginatedCitizens {
  const PaginatedCitizens({required this.items, required this.total, required this.page, required this.pageSize});

  final List<Citizen> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasNextPage => page * pageSize < total;
  int get totalPages => total == 0 ? 1 : (total / pageSize).ceil();
}
