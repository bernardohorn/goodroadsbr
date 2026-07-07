import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.cards,
    required super.occurrencesByMonth,
    required super.occurrencesByCategory,
    required super.recent,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final cardsJson = json['cards'] as Map<String, dynamic>;
    final monthsJson = json['occurrencesByMonth'] as List<dynamic>;
    final categoriesJson = json['occurrencesByCategory'] as List<dynamic>;
    final recentJson = json['recent'] as List<dynamic>;

    return DashboardStatsModel(
      cards: DashboardCards(
        total: cardsJson['total'] as int,
        pendentes: cardsJson['pendentes'] as int,
        emAndamento: cardsJson['emAndamento'] as int,
        resolvidas: cardsJson['resolvidas'] as int,
        canceladas: cardsJson['canceladas'] as int,
        totalCidadaos: cardsJson['totalCidadaos'] as int,
      ),
      occurrencesByMonth: monthsJson
          .map((m) => MonthlyCount(month: m['month'] as String, total: m['total'] as int))
          .toList(),
      occurrencesByCategory: categoriesJson
          .map((c) => CategoryCount(categoryName: c['categoryName'] as String, total: c['total'] as int))
          .toList(),
      recent: recentJson.map((o) {
        final category = o['category'] as Map<String, dynamic>?;
        final citizen = o['citizen'] as Map<String, dynamic>?;
        return RecentOccurrence(
          id: o['id'] as String,
          protocolNumber: o['protocolNumber'] as String,
          description: o['description'] as String,
          status: o['status'] as String,
          categoryName: category?['name'] as String?,
          citizenName: citizen?['name'] as String?,
          createdAt: DateTime.parse(o['createdAt'] as String),
        );
      }).toList(),
    );
  }
}
