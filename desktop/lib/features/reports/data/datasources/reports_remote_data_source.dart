import 'dart:typed_data';
import 'package:dio/dio.dart';

class ReportsRemoteDataSource {
  const ReportsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Uint8List> export({
    required String format,
    String? status,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _dio.get<List<int>>(
      '/reports/export',
      queryParameters: {
        'format': format,
        'status': ?status,
        'categoryId': ?categoryId,
        if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? []);
  }
}
