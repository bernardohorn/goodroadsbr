import 'package:flutter/material.dart';

/// Paleta de marca do GoodRoads. Um unico ponto de verdade para cores que
/// nao vem diretamente do ColorScheme gerado pelo Material 3 (ex.: cores de
/// status das ocorrencias, que precisam ser consistentes em claro/escuro).
class AppColors {
  AppColors._();

  static const seed = Color(0xFF1B7A3E);

  static const statusPendente = Color(0xFFE8A33D);
  static const statusEmAndamento = Color(0xFF3D7DE8);
  static const statusResolvida = Color(0xFF2F9E52);
  static const statusCancelada = Color(0xFF8C8C8C);
}
