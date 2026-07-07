import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/dashboard_remote_data_source.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../../../core/error/result.dart';

final dashboardRemoteDataSourceProvider = Provider((ref) => DashboardRemoteDataSource(ref.watch(dioProvider)));

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider)),
);

final getDashboardStatsUseCaseProvider =
    Provider((ref) => GetDashboardStatsUseCase(ref.watch(dashboardRepositoryProvider)));

/// `FutureProvider.autoDispose` (nao precisa de controller proprio: a tela
/// so le e recarrega, sem mutacoes locais de estado).
final dashboardStatsProvider = FutureProvider.autoDispose<Result<DashboardStats>>((ref) {
  return ref.watch(getDashboardStatsUseCaseProvider)();
});
