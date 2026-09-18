import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here
      },
    );

    // Request permissions for Android 13+
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    // Request permissions for Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Set up foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        
        showNotification(
          id: message.messageId.hashCode,
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  Future<void> updateFCMToken(String tokenOrMobile, {bool isCustomer = false}) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        debugPrint("FCM Token: $fcmToken");
        String apiBaseUrl = 'http://127.0.0.1:3000';
        try {
          if (Platform.isAndroid) {
            apiBaseUrl = 'http://127.0.0.1:3000';
          }
        } catch (_) {}
        
        final uri = Uri.parse(isCustomer ? '$apiBaseUrl/api/customer/update-fcm' : '$apiBaseUrl/api/exec/update-fcm');
        final headers = {'Content-Type': 'application/json'};
        if (!isCustomer) headers['Authorization'] = 'Bearer $tokenOrMobile';
        
        await http.post(uri, headers: headers, body: json.encode({
          'fcmToken': fcmToken,
          if (isCustomer) 'mobile': tokenOrMobile,
        }));
      }
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }

  void startForegroundPolling(String tokenOrMobile, {bool isCustomer = false}) {
    // Replaced polling with FCM token updating
    updateFCMToken(tokenOrMobile, isCustomer: isCustomer);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel_id_v2',
      'Default Notifications',
      channelDescription: 'Standard notification channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true);
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
