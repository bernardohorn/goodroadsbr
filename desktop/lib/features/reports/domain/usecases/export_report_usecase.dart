import 'dart:typed_data';
import '../../../../core/error/result.dart';
import '../repositories/reports_repository.dart';

class ExportReportUseCase {
  const ExportReportUseCase(this._repo);
  final ReportsRepository _repo;

  Future<Result<Uint8List>> call({
    required String format,
    String? status,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return _repo.export(format: format, status: status, categoryId: categoryId, dateFrom: dateFrom, dateTo: dateTo);
  }
}
