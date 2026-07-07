import 'package:dio/dio.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._dio);
  final Dio _dio;

  Future<DashboardStatsModel> getStats() async {
    final response = await _dio.get('/dashboard/stats');
    return DashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
