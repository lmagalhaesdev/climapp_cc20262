// lib/src/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Instância singleton para acesso global
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Plugin de notificações locais (para exibir banner nativo no Android em foreground)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Chave global para permitir navegação sem BuildContext
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> initialize() async {
    // 0. Inicializar flutter_local_notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings: initSettings,
    );

    // Sempre configurar os handlers para escutar mensagens em foreground/background
    _setupMessageHandlers();

    // 1. Solicitar permissões (Obrigatório para iOS e Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Permissão concedida pelo usuário.');

      // 2. Obter o FCM Token na inicialização
      try {
        String? token = await _fcm.getToken();
        debugPrint('====================================');
        debugPrint('FCM TOKEN DO DISPOSITIVO: $token');
        debugPrint('====================================');
      } catch (e) {
        debugPrint('Erro ao obter token FCM: $e');
      }

      // Escuta caso o token seja renovado pelo Firebase
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token atualizado: $newToken');
      });

      // 3. Forçar exibição do banner nativo mesmo com o app em foreground (iOS)
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      debugPrint('Permissão negada ou não configurada.');
    }
  }

  void _setupMessageHandlers() {
    // Cenário: Foreground (App aberto na tela)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ??
          message.data['title'] ??
          'Notificação recebida';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      debugPrint('Mensagem recebida em Foreground: $title');

      // Exibe a notificação nativa do sistema via flutter_local_notifications
      _showLocalNotification(title: title, body: body);
    });

    // Cenário: Background (App minimizado e usuário clica na notificação)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Toque na notificação (Background): ${message.data}');
      _handleDeepLink(message);
    });

    // Cenário: Terminated (App fechado e aberto pelo clique na notificação)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App inicializado a partir de notificação: ${message.data}');
        _handleDeepLink(message);
      }
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'fcm_foreground_channel', // ID do canal (único por app)
      'Notificações em Primeiro Plano', // Nome visível nas configurações do Android
      channelDescription: 'Exibe notificações recebidas com o app aberto',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  void _handleDeepLink(RemoteMessage message) {
    final city = message.data['city'];
    if (city != null) {
      // Navega diretamente para a tela de clima da cidade
      navigatorKey.currentState?.pushNamed('/weather', arguments: city);
    }
  }
}
