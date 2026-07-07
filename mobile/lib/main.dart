import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/providers.dart';
import 'core/push/push_registration_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  final sharedPreferences = await SharedPreferences.getInstance();

  // Push (Etapa 5, decisao do cliente: Firebase Cloud Messaging — ver
  // docs/DECISOES.md). Exige `flutterfire configure` previamente rodado
  // (gera `firebase_options.dart`, nao versionado neste repositorio porque
  // depende de um projeto Firebase real — ver mobile/README.md). Sem essa
  // configuracao, `Firebase.initializeApp()` lanca e o app segue
  // normalmente, apenas sem notificacoes push.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Ver comentario acima — degradacao graciosa.
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
      child: const CitizenApp(),
    ),
  );
}
