import '../../../../core/error/result.dart';
import '../entities/citizen.dart';
import '../entities/paginated_citizens.dart';

abstract class CitizensRepository {
  Future<Result<PaginatedCitizens>> list({required int page, String? search});
  Future<Result<Citizen>> updateStatus({required String id, required bool active});
}
