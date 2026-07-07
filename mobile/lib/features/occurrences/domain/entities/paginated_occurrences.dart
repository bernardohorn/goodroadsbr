import 'occurrence.dart';

class PaginatedOccurrences {
  const PaginatedOccurrences({required this.items, required this.total, required this.page, required this.pageSize});

  final List<Occurrence> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasNextPage => page * pageSize < total;
}
