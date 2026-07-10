import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/citizen.dart';
import '../../domain/entities/paginated_citizens.dart';
import '../../domain/repositories/citizens_repository.dart';
import '../datasources/citizens_remote_data_source.dart';

class CitizensRepositoryImpl implements CitizensRepository {
  const CitizensRepositoryImpl(this._remote);
  final CitizensRemoteDataSource _remote;

  static const _pageSize = 20;

  @override
  Future<Result<PaginatedCitizens>> list({required int page, String? search}) async {
    try {
      final result = await _remote.list(page: page, search: search);
      return Result.success(
        PaginatedCitizens(items: result.items, total: result.total, page: page, pageSize: _pageSize),
      );
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<Citizen>> updateStatus({required String id, required bool active}) async {
    try {
      return Result.success(await _remote.updateStatus(id: id, active: active));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
