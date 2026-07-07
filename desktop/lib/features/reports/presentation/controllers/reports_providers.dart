import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../data/datasources/reports_remote_data_source.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/usecases/export_report_usecase.dart';

final reportsRemoteDataSourceProvider = Provider((ref) => ReportsRemoteDataSource(ref.watch(dioProvider)));

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepositoryImpl(ref.watch(reportsRemoteDataSourceProvider)),
);

final exportReportUseCaseProvider = Provider((ref) => ExportReportUseCase(ref.watch(reportsRepositoryProvider)));
