import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/providers.dart';
import 'core/offline/offline_providers.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Raiz do app do cidadao (Android/iOS). O app do funcionario (Windows)
/// vive em `../../desktop`, como um projeto Flutter independente — ver
/// docs/ARQUITETURA_GOODROADS.md, secao 7.1.
class CitizenApp extends ConsumerStatefulWidget {
  const CitizenApp({super.key});

  @override
  ConsumerState<CitizenApp> createState() => _CitizenAppState();
}

class _CitizenAppState extends ConsumerState<CitizenApp> {
  @override
  void initState() {
    super.initState();
    // Inicializa o FCM depois do primeiro frame, quando o `go_router` ja
    // esta disponivel para navegar ate a ocorrencia ao tocar em uma
    // notificacao (ver core/push/push_registration_service.dart). Se o
    // Firebase nao estiver configurado neste build (flutterfire configure
    // nao rodado — ver mobile/README.md), falha silenciosamente e o app
    // segue funcionando normalmente, so sem push.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(pushRegistrationServiceProvider).initialize(
          onNotificationTap: (event) {
            if (event.occurrenceId != null) {
              ref.read(appRouterProvider).push(AppRoutes.occurrenceDetailsPath(event.occurrenceId!));
            }
          },
        );
      } catch (_) {
        // Degrada graciosamente — ver comentario acima.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Mantem o listener de conectividade vivo enquanto o app inteiro
    // estiver aberto (ver core/offline/offline_providers.dart) — dispara a
    // sincronizacao da fila offline assim que a rede voltar.
    ref.watch(connectivitySyncControllerProvider);

    return MaterialApp.router(
      title: 'GoodRoads',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
