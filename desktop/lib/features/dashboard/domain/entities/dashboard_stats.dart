class DashboardCards {
  const DashboardCards({
    required this.total,
    required this.pendentes,
    required this.emAndamento,
    required this.resolvidas,
    required this.canceladas,
    required this.totalCidadaos,
  });

  final int total;
  final int pendentes;
  final int emAndamento;
  final int resolvidas;
  final int canceladas;
  final int totalCidadaos;
}

class MonthlyCount {
  const MonthlyCount({required this.month, required this.total});
  final String month; // 'YYYY-MM'
  final int total;
}

class CategoryCount {
  const CategoryCount({required this.categoryName, required this.total});
  final String categoryName;
  final int total;
}

class RecentOccurrence {
  const RecentOccurrence({
    required this.id,
    required this.protocolNumber,
    required this.description,
    required this.status,
    this.categoryName,
    this.citizenName,
    required this.createdAt,
  });

  final String id;
  final String protocolNumber;
  final String description;
  final String status;
  final String? categoryName;
  final String? citizenName;
  final DateTime createdAt;
}

class DashboardStats {
  const DashboardStats({
    required this.cards,
    required this.occurrencesByMonth,
    required this.occurrencesByCategory,
    required this.recent,
  });

  final DashboardCards cards;
  final List<MonthlyCount> occurrencesByMonth;
  final List<CategoryCount> occurrencesByCategory;
  final List<RecentOccurrence> recent;
}
