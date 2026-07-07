import '../../../../core/error/result.dart';
import '../../../../core/network/failure_mapper.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_data_source.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._remote);
  final CategoriesRemoteDataSource _remote;

  @override
  Future<Result<List<Category>>> list() async {
    try {
      return Result.success(await _remote.list());
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<Category>> create({required String name, String? icon, String? color}) async {
    try {
      return Result.success(await _remote.create(name: name, icon: icon, color: color));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }

  @override
  Future<Result<Category>> update({required String id, String? name, String? icon, String? color, bool? active}) async {
    try {
      return Result.success(await _remote.update(id: id, name: name, icon: icon, color: color, active: active));
    } catch (error) {
      return Result.failure(mapErrorToFailure(error));
    }
  }
}
