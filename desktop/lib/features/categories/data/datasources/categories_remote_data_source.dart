import 'package:dio/dio.dart';
import '../models/category_model.dart';

class CategoriesRemoteDataSource {
  const CategoriesRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<CategoryModel>> list() async {
    final response = await _dio.get('/categories');
    return (response.data as List<dynamic>).map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<CategoryModel> create({required String name, String? icon, String? color}) async {
    final response = await _dio.post(
      '/categories',
      data: {'name': name, 'icon': ?icon, 'color': ?color},
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CategoryModel> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? active,
  }) async {
    final response = await _dio.patch(
      '/categories/$id',
      data: {
        'name': ?name,
        'icon': ?icon,
        'color': ?color,
        'active': ?active,
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
