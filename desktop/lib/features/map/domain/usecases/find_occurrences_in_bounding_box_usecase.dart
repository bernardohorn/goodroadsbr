import '../../../../core/error/result.dart';
import '../entities/bounding_box.dart';
import '../entities/occurrence_pin.dart';
import '../repositories/map_repository.dart';

class FindOccurrencesInBoundingBoxUseCase {
  const FindOccurrencesInBoundingBoxUseCase(this._repo);
  final MapRepository _repo;

  Future<Result<List<OccurrencePin>>> call(BoundingBox box, {String? status, String? categoryId}) {
    return _repo.findInBoundingBox(box, status: status, categoryId: categoryId);
  }
}
