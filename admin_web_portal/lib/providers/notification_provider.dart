// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../widgets/notification_bell.dart'; // To use NotificationItem

class NotificationProvider with ChangeNotifier {
  final WebSocketService webSocketService;

  List<NotificationItem> notifications = [];

  NotificationProvider({required this.webSocketService}) {
    _init();
  }

  void _init() {
    webSocketService.addListener(_handleUpdate);
  }

  void _handleUpdate(dynamic payload) {
    if (payload != null && payload['type'] != null) {
      final type = payload['type'];
      final eventData = payload['data'] ?? {};
      
      String message = payload['message'] ?? 'New notification received';
      if (type == 'NEW_WORK_ORDER') {
         message = 'New booking created: ${eventData['orderId'] ?? eventData['id'] ?? 'Unknown'}';
      } else if (type == 'STATUS_UPDATE') {
         message = 'Booking ${eventData['orderId'] ?? eventData['id']} status updated to ${eventData['status']}';
      } else if (type == 'EXECUTIVE_UPDATE') {
         message = 'Status: ${eventData['status'] ?? 'Updated'}';
      } else if (type == 'RATING_UPDATE') {
         message = 'Order ID ${eventData['orderId'] ?? eventData['id']} and ${eventData['rating'] ?? 0}/5';
      }
      
      // We can generate an id using current timestamp
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      MaterialColor color = Colors.blue;
      String title = 'Notification';
      int? mainIndex;
      int? subIndex;

      if (type == 'NEW_WORK_ORDER') {
        color = Colors.green;
        title = 'New Booking';
        mainIndex = 1; // Work Orders
        subIndex = 0; // New / All
      } else if (type == 'STATUS_UPDATE') {
        color = Colors.purple;
        title = 'Status Update';
        mainIndex = 1; // Work Orders
      } else if (type == 'EXECUTIVE_UPDATE') {
        color = Colors.orange;
        title = '${eventData['firstName'] ?? 'Executive'} (${eventData['employeeId'] ?? 'ID'})';
        mainIndex = 2; // Employees tab
      } else if (type == 'RATING_UPDATE') {
        color = Colors.amber;
        title = 'Rating Update';
        mainIndex = 1; // Work Orders
      } else {
        color = Colors.blue;
        title = 'System Update';
      }

      notifications.insert(
        0,
        NotificationItem(
          id: id,
          title: title,
          subtitle: message,
          color: color,
          targetMainIndex: mainIndex,
          targetSubIndex: subIndex,
        ),
      );

      notifyListeners();
      _playAlertSound();
    }
  }

  Future<void> _playAlertSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customSound = prefs.getString('custom_alert_sound');
      
      String audioUrl;
      if (customSound != null && customSound.isNotEmpty) {
        if (customSound.startsWith('data:audio')) {
          audioUrl = customSound;
        } else {
          // Backwards compatibility for old saved strings that were just base64
          audioUrl = 'data:audio/wav;base64,$customSound';
        }
      } else {
        // Fallback to a short beep wave base64
        audioUrl = 'data:audio/wav;base64,UklGRlYDAABXQVZFZm10IBAAAAABAAEAQB8AAIA+AAACABAAZGF0YTIBAABAAQAAQAEAADkAAAAAAAAA/v8AAP7/AAAAAAAA//8AAAAAAAAAAP//AAAAAAAAAAD//wAAAAAAAAAAAAAAAAAA'; 
      }
      
      if (audioUrl.isNotEmpty) {
        final audio = html.AudioElement(audioUrl);
        audio.play();
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void clearAll() {
    notifications.clear();
    notifyListeners();
  }

  void removeNotification(String id) {
    notifications.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    webSocketService.removeListener(_handleUpdate);
    super.dispose();
  }
}
