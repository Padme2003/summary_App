import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Inicializar servicio de notificaciones
  Future<void> initialize() async {
    try {
      // Solicitar permisos
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permisos de notificaciones concedidos');

        // Inicializar notificaciones locales
        await _initializeLocalNotifications();

        // Obtener FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('📱 FCM Token: $_fcmToken');

        // Escuchar cambios en el token
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('🔄 FCM Token actualizado: $newToken');
          // Aquí deberías enviar el token al backend
        });

        // Configurar handlers
        _setupMessageHandlers();
      } else {
        debugPrint('⚠️  Permisos de notificaciones denegados');
      }
    } catch (e) {
      debugPrint('❌ Error al inicializar notificaciones: $e');
    }
  }

  // Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📬 Notificación tocada: ${response.payload}');
        // Manejar tap en notificación
        _handleNotificationTap(response.payload);
      },
    );
  }

  // Configurar handlers de mensajes
  void _setupMessageHandlers() {
    // Mensaje recibido cuando app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Mensaje recibido (foreground): ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Mensaje recibido cuando app está en background y se toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notificación abierta (background): ${message.notification?.title}');
      _handleNotificationMessage(message);
    });

    // Verificar si la app fue abierta desde una notificación
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📬 App abierta desde notificación: ${message.notification?.title}');
        _handleNotificationMessage(message);
      }
    });
  }

  // Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sumly_notifications',
      'Sumly Notifications',
      channelDescription: 'Notificaciones de la app Sumly',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  // Manejar tap en notificación
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      debugPrint('Payload: $payload');
      // Aquí puedes navegar a una pantalla específica según el payload
    }
  }

  // Manejar mensaje de notificación
  void _handleNotificationMessage(RemoteMessage message) {
    final data = message.data;

    // Navegar según el tipo de notificación
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'summary_ready':
          // Navegar a la pantalla de resumen
          debugPrint('Navegar a resumen: ${data['summaryId']}');
          break;
        case 'audiobook_ready':
          // Navegar a la pantalla de audiobook
          debugPrint('Navegar a audiobook: ${data['audiobookId']}');
          break;
        default:
          debugPrint('Tipo de notificación desconocido: ${data['type']}');
      }
    }
  }

  // Suscribirse a un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al topic: $topic');
    } catch (e) {
      debugPrint('❌ Error al suscribirse al topic $topic: $e');
    }
  }

  // Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del topic: $topic');
    } catch (e) {
      debugPrint('❌ Error al desuscribirse del topic $topic: $e');
    }
  }

  // Enviar token al backend
  Future<void> sendTokenToBackend(String token) async {
    try {
      // Aquí deberías enviar el token a tu backend
      // await http.post(
      //   Uri.parse('${ApiConfig.baseUrl}/notifications/register'),
      //   headers: {'Authorization': 'Bearer $authToken'},
      //   body: jsonEncode({'fcmToken': token}),
      // );
      debugPrint('📤 Token enviado al backend: $token');
    } catch (e) {
      debugPrint('❌ Error al enviar token al backend: $e');
    }
  }
}

// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Mensaje recibido en background: ${message.notification?.title}');
}
