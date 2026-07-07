import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/staff_user_model.dart';

/// Unica classe que conhece os endpoints REST de autenticacao
/// (ver backend/src/modules/auth). O repository nunca monta uma URL ou
/// interpreta um `Response` diretamente — isso fica isolado aqui.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthResponseModel> login({required String email, required String password}) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) {
    return _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  }

  Future<void> forgotPassword(String email) {
    return _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({required String token, required String newPassword}) {
    return _dio.post('/auth/reset-password', data: {'token': token, 'newPassword': newPassword});
  }

  Future<StaffUserModel> fetchCurrentUser() async {
    final response = await _dio.get('/users/me');
    return StaffUserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StaffUserModel> updateProfile({String? name, String? phone}) async {
    final response = await _dio.patch(
      '/users/me',
      data: {'name': ?name, 'phone': ?phone},
    );
    return StaffUserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
