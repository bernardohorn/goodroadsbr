import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';

/// Preferencia de tema (claro/escuro/sistema), persistida localmente via
/// `LocalPreferencesService`. Consumida em `app.dart` (raiz do MaterialApp)
/// e controlada na tela Configurações.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.read(localPreferencesServiceProvider).getThemeMode();
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await ref.read(localPreferencesServiceProvider).setThemeMode(value);
  }
}

final themeModeControllerProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
