import 'dart:io';
import 'package:dio/dio.dart';

/// Fala com `POST/DELETE /api/v1/notifications/devices` (ver
/// backend/src/modules/notifications). Falhas aqui nunca devem travar o
/// fluxo de login/logout — push e um "extra", nao um requisito para usar o
/// app — por isso os metodos engolem erros silenciosamente (o pior caso e
/// o usuario nao receber notificacoes push, nao perder acesso ao app).
class DeviceRegistrationRepository {
  const DeviceRegistrationRepository(this._dio);
  final Dio _dio;

  Future<void> register(String token) async {
    try {
      await _dio.post('/notifications/devices', data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'});
    } catch (_) {
      // Silencioso de proposito — ver docstring da classe.
    }
  }

  Future<void> unregister(String token) async {
    try {
      await _dio.delete('/notifications/devices', data: {'token': token});
    } catch (_) {
      // Silencioso de proposito — ver docstring da classe.
    }
  }
}
