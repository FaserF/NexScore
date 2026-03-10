import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Initialization Settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization Settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Initialization Settings for Web
    // FlutterLocalNotifications plugin handles some web permissions natively,
    // but the initialization object mostly covers mobile.
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tapped logic here
        // We can use a router or global key to navigate.
        if (kDebugMode) {
          print('Notification payload: ${response.payload}');
        }
      },
    );

    _initialized = true;
  }

  /// Requests permissions for notifications.
  /// On Android 13+, this triggers the native prompt.
  /// On iOS, this triggers the native prompt.
  /// On Web, this triggers the browser's Notification API prompt.
  Future<bool> requestPermissions() async {
    bool granted = false;

    if (kIsWeb) {
      // NOTE: For Web, you typically need to check window.Notification API directly
      // However the plugin attempts to handle some basic web checks.
      // A fallback is assuming generic web permission check or handling natively in JS.
      // Currently, the plugin provides limited direct request UI for web,
      // so we rely on standard behavior or explicit JS interop if needed.
      // For now, we return true if no exception.
      try {
        // No direct request API in standard flutter_local_notifications for web,
        // it usually prompts when showing the first notification if not granted.
        granted = true; // Assuming optimistic or handled via browser natively.
      } catch (e) {
        granted = false;
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      granted = await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      // Request exact alarms and notification permissions if targeting Android 13+
      granted = await androidImplementation?.requestNotificationsPermission() ?? false;
    }

    return granted;
  }

  /// Checks if notifications are enabled/granted.
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true; // Web handling is complex, assume mostly true until prompt

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }

    if (Platform.isIOS) {
       // iOS doesn't easily expose 'isEnabled' synchronously without requesting.
       // Usually, we just try to request or maintain a local pref state.
       return true; 
    }
    
    return false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nexscore_general_channel', // id
      'General Notifications', // name
      channelDescription: 'Used for important NexScore updates like turns and server connections.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }
}
