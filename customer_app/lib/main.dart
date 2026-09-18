import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/api_data_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/customer_main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiDataProvider()),
      ],
      child: const CustomerApp(),
    ),
  );
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AuthScreen(),
        '/main': (context) => const CustomerMainScreen(),
      },
    );
  }
}
