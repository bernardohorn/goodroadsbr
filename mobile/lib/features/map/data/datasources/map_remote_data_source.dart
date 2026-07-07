import 'package:dio/dio.dart';
import '../../domain/entities/bounding_box.dart';
import '../models/occurrence_pin_model.dart';

class MapRemoteDataSource {
  const MapRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<OccurrencePinModel>> findInBoundingBox(BoundingBox box, {String? status}) async {
    final response = await _dio.get(
      '/map/occurrences',
      queryParameters: {
        'north': box.north,
        'south': box.south,
        'east': box.east,
        'west': box.west,
        'status': ?status,
      },
    );
    final items = (response.data as Map<String, dynamic>)['items'] as List<dynamic>;
    return items.map((item) => OccurrencePinModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
