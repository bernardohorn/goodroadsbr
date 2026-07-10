import 'package:dio/dio.dart';
import '../models/citizen_model.dart';

class CitizensRemoteDataSource {
  const CitizensRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({List<CitizenModel> items, int total})> list({required int page, String? search}) async {
    final response = await _dio.get(
      '/citizens',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>).map((item) => CitizenModel.fromJson(item as Map<String, dynamic>)).toList();
    return (items: items, total: data['total'] as int);
  }

  Future<CitizenModel> updateStatus({required String id, required bool active}) async {
    final response = await _dio.patch('/citizens/$id/status', data: {'active': active});
    return CitizenModel.fromJson(response.data as Map<String, dynamic>);
  }
}
