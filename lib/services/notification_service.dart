import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Top-level background message handler required by FCM protocol for mobile
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background notification payload: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request Permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Setup Local Notifications (Skip for Web as it has its own logic)
    if (!kIsWeb) {
      // Configure Background lifecycle engine hook
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // ADDED: Explicit Android High-Importance channel setup to force heads-up visual alerts
      const AndroidNotificationChannel highPriorityChannel = AndroidNotificationChannel(
        'campus_channel', // Matches your channel id below
        'Campus Transmissions', // Matches your channel name below
        description: 'Urgent updates regarding campus grids and deadlines.',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(highPriorityChannel);

      // Listen for Incoming Transmissions
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // 3. Subscribe to the Global Bahria Topic (MOBILE ONLY)
      await _fcm.subscribeToTopic("campus_updates");

      // ADDED: Print Device Registration Token to console for painless developer testing via Firebase
      String? token = await _fcm.getToken();
      debugPrint("====================================================");
      debugPrint("CAMPUS CONNECT FCM DEVICE TOKEN: $token");
      debugPrint("====================================================");
    } else {
      // Logic for Web: Browsers handle background notifications via Service Workers
      print("System: Notification Service initialized on Web (Topic Subscription Skipped)");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // We only call this on Mobile
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'campus_channel',
      'Campus Transmissions',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF00E5FF),
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.notification.hashCode, // Dynamically handle IDs to prevent message overwrites
      message.notification?.title ?? "New Transmission",
      message.notification?.body ?? "Check the grid for updates.",
      platformDetails,
    );
  }
}