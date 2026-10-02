// lib/src/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // Instância singleton para acesso global
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Chave global para permitir navegação sem BuildContext
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> initialize() async {
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
      final body = message.notification?.body ??
          message.data['body'] ??
          '';

      debugPrint('Mensagem recebida em Foreground: $title');

      showInAppNotification(
        title: title,
        body: body,
        message: message,
      );
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

  void showInAppNotification({
    required String title,
    required String body,
    RemoteMessage? message,
  }) {
    final snackBar = SnackBar(
      content: Text(body.isNotEmpty ? '$title\n$body' : title),
      backgroundColor: Colors.blueAccent,
      duration: const Duration(seconds: 4),
    );

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(snackBar);
    } else {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void _handleDeepLink(RemoteMessage message) {
    final city = message.data['city'];
    if (city != null) {
      // Navega diretamente para a tela de clima da cidade
      navigatorKey.currentState?.pushNamed('/weather', arguments: city);
    }
  }
}
