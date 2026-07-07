import 'package:flutter/material.dart';

/// Paleta de marca do GoodRoads. Mesma seed color do app mobile, para
/// consistencia visual entre cidadao e prefeitura — um unico ponto de
/// verdade para cores que nao vem diretamente do ColorScheme gerado pelo
/// Material 3 (ex.: cores de status das ocorrencias).
class AppColors {
  AppColors._();

  static const seed = Color(0xFF1B7A3E);

  static const statusPendente = Color(0xFFE8A33D);
  static const statusEmAndamento = Color(0xFF3D7DE8);
  static const statusResolvida = Color(0xFF2F9E52);
  static const statusCancelada = Color(0xFF8C8C8C);

  static const priorityBaixa = Color(0xFF8C8C8C);
  static const priorityMedia = Color(0xFF3D7DE8);
  static const priorityAlta = Color(0xFFE8A33D);
  static const priorityUrgente = Color(0xFFD64545);

  static const sidebarBackground = Color(0xFF10281B);
}
