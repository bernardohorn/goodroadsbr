import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Envelope de uma notificacao push recebida — repassado para quem escuta
/// (ex.: para navegar ate os detalhes da ocorrencia quando o usuario toca
/// na notificacao).
class PushNotificationEvent {
  const PushNotificationEvent({required this.title, required this.body, this.occurrenceId});
  final String title;
  final String body;
  final String? occurrenceId;
}

/// Handler de mensagens em background/terminado. Precisa ser uma funcao
/// top-level (nao um metodo de classe) por exigencia do plugin
/// `firebase_messaging` — e executada em um isolate separado.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nao ha nada a fazer aqui alem de deixar o SO exibir a notificacao
  // (comportamento padrao do FCM quando o app esta em background/fechado
  // e o payload tem um bloco `notification`). Se no futuro for necessario
  // processar dados em background (ex.: atualizar contador local), este e
  // o lugar.
}

/// Encapsula toda a integracao com o Firebase Cloud Messaging. Nenhuma
/// outra parte do app importa `firebase_messaging` diretamente — troca de
/// provedor de push no futuro (decisao do cliente, ver docs/DECISOES.md)
/// fica restrita a este arquivo.
class PushRegistrationService {
  PushRegistrationService()
      : _messaging = FirebaseMessaging.instance,
        _localNotifications = FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  void Function(PushNotificationEvent)? _onNotificationTap;

  Future<void> initialize({required void Function(PushNotificationEvent) onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final occurrenceId = response.payload;
        _onNotificationTap?.call(PushNotificationEvent(title: '', body: '', occurrenceId: occurrenceId));
      },
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Notificacoes em foreground nao aparecem sozinhas no Android (ao
    // contrario do iOS) — por isso exibimos manualmente via
    // flutter_local_notifications quando o app esta aberto.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App aberto a partir de uma notificacao tocada com o app em background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(message));

    // App aberto a partir de uma notificacao tocada com o app fechado.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goodroads_status_changes',
          'Atualizações de ocorrências',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['occurrenceId'] as String?,
    );
  }

  void _handleTap(RemoteMessage message) {
    _onNotificationTap?.call(
      PushNotificationEvent(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        occurrenceId: message.data['occurrenceId'] as String?,
      ),
    );
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
