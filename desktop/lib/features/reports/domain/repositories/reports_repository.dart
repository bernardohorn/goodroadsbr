import 'dart:typed_data';
import '../../../../core/error/result.dart';

abstract class ReportsRepository {
  Future<Result<Uint8List>> export({
    required String format,
    String? status,
    String? categoryId,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
}
