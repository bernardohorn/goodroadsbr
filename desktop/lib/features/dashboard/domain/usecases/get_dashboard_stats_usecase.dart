import '../../../../core/error/result.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  const GetDashboardStatsUseCase(this._repo);
  final DashboardRepository _repo;

  Future<Result<DashboardStats>> call() => _repo.getStats();
}
