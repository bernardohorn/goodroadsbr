import 'dart:typed_data';
import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._remote);
  final ReportsRemoteDataSource _remote;

  @override
  Future<Result<Uint8List>> export({
    required String format,
    String? status,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      return Result.success(
        await _remote.export(format: format, status: status, categoryId: categoryId, dateFrom: dateFrom, dateTo: dateTo),
      );
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
