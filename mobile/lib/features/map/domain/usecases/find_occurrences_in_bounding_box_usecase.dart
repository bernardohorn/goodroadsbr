import '../../../../core/error/result.dart';
import '../entities/bounding_box.dart';
import '../entities/occurrence_pin.dart';
import '../repositories/map_repository.dart';

class FindOccurrencesInBoundingBoxUseCase {
  const FindOccurrencesInBoundingBoxUseCase(this._repository);
  final MapRepository _repository;

  Future<Result<List<OccurrencePin>>> call(BoundingBox box, {String? status}) {
    return _repository.findInBoundingBox(box, status: status);
  }
}
