import '../../../../core/error/result.dart';
import '../entities/category.dart';

abstract class CategoriesRepository {
  Future<Result<List<Category>>> list();
  Future<Result<Category>> create({required String name, String? icon, String? color});
  Future<Result<Category>> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? active,
  });
}
