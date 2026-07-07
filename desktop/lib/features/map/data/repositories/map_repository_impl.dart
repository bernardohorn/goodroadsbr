import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/bounding_box.dart';
import '../../domain/entities/occurrence_pin.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_data_source.dart';

class MapRepositoryImpl implements MapRepository {
  const MapRepositoryImpl(this._remote);
  final MapRemoteDataSource _remote;

  @override
  Future<Result<List<OccurrencePin>>> findInBoundingBox(BoundingBox box, {String? status, String? categoryId}) async {
    try {
      return Result.success(await _remote.findInBoundingBox(box, status: status, categoryId: categoryId));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
