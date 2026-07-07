import '../../../../core/error/result.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Result<DashboardStats>> getStats();
}
