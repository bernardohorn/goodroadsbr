import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._remote);
  final DashboardRemoteDataSource _remote;

  @override
  Future<Result<DashboardStats>> getStats() async {
    try {
      return Result.success(await _remote.getStats());
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
