import 'package:dio/dio.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

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

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    String? cpf,
    DateTime? birthDate,
    String? phone,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'cpf': ?cpf,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        'phone': ?phone,
      },
    );
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

  Future<UserModel> fetchCurrentUser() async {
    final response = await _dio.get('/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({String? name, String? phone, String? avatarUrl}) async {
    final response = await _dio.patch(
      '/users/me',
      data: {
        'name': ?name,
        'phone': ?phone,
        'avatarUrl': ?avatarUrl,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
