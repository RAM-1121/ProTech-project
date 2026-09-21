import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/api_data_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/work_order_provider.dart';
import 'providers/notification_provider.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'screens/admin_dashboard.dart';
import 'screens/admin_login.dart';

void main() {
  final apiService = ApiService();
  final webSocketService = WebSocketService()..initSocket();

  runApp(
    MultiProvider(
      providers: [
        Provider<WebSocketService>.value(value: webSocketService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApiDataProvider()),
        ChangeNotifierProvider(
          create: (_) => WorkOrderProvider(
            apiService: apiService,
            webSocketService: webSocketService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            webSocketService: webSocketService,
          ),
        ),
      ],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProTech Cooling Services',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AdminLoginScreen(),
        '/dashboard': (context) => const AdminDashboardScreen(),
      },
    );
  }
}
