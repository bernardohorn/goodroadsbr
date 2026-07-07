import 'package:dio/dio.dart';
import '../models/staff_member_model.dart';

class StaffRemoteDataSource {
  const StaffRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<StaffMemberModel>> list({String? search}) async {
    final response = await _dio.get(
      '/staff',
      queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
    );
    return (response.data as List<dynamic>).map((s) => StaffMemberModel.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<StaffMemberModel> create({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final response = await _dio.post(
      '/staff',
      data: {'name': name, 'email': email, 'password': password, 'role': role, 'phone': ?phone},
    );
    return StaffMemberModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StaffMemberModel> update({
    required String id,
    String? name,
    String? phone,
    String? role,
    bool? active,
  }) async {
    final response = await _dio.patch(
      '/staff/$id',
      data: {
        'name': ?name,
        'phone': ?phone,
        'role': ?role,
        'active': ?active,
      },
    );
    return StaffMemberModel.fromJson(response.data as Map<String, dynamic>);
  }
}
