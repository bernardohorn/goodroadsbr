import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/section_header.dart';
import '../controllers/theme_mode_controller.dart';

/// Tela 9/10 do desktop. Escopo deliberadamente honesto: o backend nao tem
/// um modulo de "configuracoes do sistema" (nao foi pedido no briefing
/// original nem faz parte da API descrita em
/// docs/ARQUITETURA_GOODROADS.md, secao 5) — entao esta tela cobre apenas
/// preferencias reais do cliente Flutter (tema, notificacoes locais) e
/// informacoes tecnicas, em vez de simular funcionalidade que nao existe
/// de fato no servidor.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late bool _notificationsEnabled =
      ref.read(localPreferencesServiceProvider).getDesktopNotificationsEnabled();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Configurações'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro')),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Sistema')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (selection) => ref.read(themeModeControllerProvider.notifier).setThemeMode(selection.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notificações', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Avisar sobre novas ocorrências ao abrir o painel'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        ref.read(localPreferencesServiceProvider).setDesktopNotificationsEnabled(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sobre', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    const Text('GoodRoads — Painel da Prefeitura'),
                    const Text('Versão 1.0.0'),
                    Text('Servidor: ${AppConfig.apiBaseUrl}', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
