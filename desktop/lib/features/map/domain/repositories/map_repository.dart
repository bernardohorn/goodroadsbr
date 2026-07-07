import '../../../../core/error/result.dart';
import '../entities/bounding_box.dart';
import '../entities/occurrence_pin.dart';

abstract class MapRepository {
  Future<Result<List<OccurrencePin>>> findInBoundingBox(BoundingBox box, {String? status, String? categoryId});
}
