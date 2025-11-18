import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';  // Comentado temporalmente

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;  // Comentado temporalmente
  RealtimeChannel? _channel;

  NotificationService() {
    _initNotifications();
    // _initFirebaseMessaging();  // Comentado temporalmente
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar la acción cuando se toca la notificación
        debugPrint('Notificación tocada: ${details.payload}');
        // Aquí puedes agregar navegación basada en el payload
      },
    );
  }

  // TODO: Descomentar cuando se agregue Firebase
  // Future<void> _initFirebaseMessaging() async {
  //   // Solicitar permisos
  //   final settings = await _firebaseMessaging.requestPermission(
  //     alert: true,
  //     announcement: false,
  //     badge: true,
  //     carPlay: false,
  //     criticalAlert: false,
  //     provisional: false,
  //     sound: true,
  //   );
  //
  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     debugPrint('Usuario otorgó permiso para notificaciones');
  //     await _saveFcmToken();
  //   }
  //
  //   // Escuchar mensajes en segundo plano
  //   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //
  //   // Escuchar mensajes en primer plano
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     debugPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
  //     _showNotification(
  //       title: message.notification?.title ?? 'Nueva notificación',
  //       body: message.notification?.body,
  //       payload: message.data['payload'],
  //     );
  //   });
  // }

  // Manejador de mensajes en segundo plano
  // @pragma('vm:entry-point')
  // static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //   // Inicializar plugins necesarios
  //   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //       FlutterLocalNotificationsPlugin();
  //   
  //   // Configurar notificación local
  //   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const iosSettings = DarwinInitializationSettings();
  //   const initSettings = InitializationSettings(
  //     android: androidSettings,
  //     iOS: iosSettings,
  //   );
  //   
  //   await flutterLocalNotificationsPlugin.initialize(initSettings);
  //   
  //   // Mostrar notificación
  //   const androidDetails = AndroidNotificationDetails(
  //     'sorteo_channel',
  //     'Resultados de Sorteos',
  //     channelDescription: 'Notificaciones sobre resultados de sorteos',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     ticker: 'ticker',
  //   );
  //   
  //   const iosDetails = DarwinNotificationDetails();
  //   const notificationDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: iosDetails,
  //   );
  //   
  //   await flutterLocalNotificationsPlugin.show(
  //     message.hashCode,
  //     message.notification?.title,
  //     message.notification?.body,
  //     notificationDetails,
  //     payload: message.data['payload'],
  //   );
  // }

  // Guardar el token de FCM en Supabase
  // Future<void> _saveFcmToken() async {
  //   try {
  //     final token = await _firebaseMessaging.getToken();
  //     if (token == null) return;
  //     
  //     final prefs = await SharedPreferences.getInstance();
  //     final savedToken = prefs.getString(_fcmTokenKey);
  //     
  //     // Solo actualizar si el token ha cambiado
  //     if (savedToken != token) {
  //       final userId = _supabase.auth.currentUser?.id;
  //       if (userId != null) {
  //         await _supabase
  //             .from('user_tokens')
  //             .upsert({
  //               'user_id': userId,
  //               'fcm_token': token,
  //               'updated_at': DateTime.now().toIso8601String(),
  //             });
  //         
  //         await prefs.setString(_fcmTokenKey, token);
  //         debugPrint('Token de FCM guardado correctamente');
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('Error al guardar el token de FCM: $e');
  //   }
  // }

  // Método para mostrar notificaciones locales (comentado temporalmente)
  /*
  Future<void> _showNotification({
    required String title,
    String? body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sorteo_channel',
      'Resultados de Sorteos',
      channelDescription: 'Notificaciones sobre resultados de sorteos',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        0, // id
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error al mostrar notificación local: $e');
    }
  }
  */

  // Suscribirse a actualizaciones de sorteos (temporalmente simplificado)
  RealtimeChannel subscribeToDraws(String userId) {
    // Cancelar suscripción anterior si existe
    _channel?.unsubscribe();

    // Crear canal básico sin handlers (evita errores por cambios de API)
    _channel = _supabase.channel('sorteos_$userId');
    _channel!.subscribe();
    return _channel!;
  }

  // Cancelar suscripción
  void unsubscribe() {
    _channel?.unsubscribe();
  }
}
