import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/api_data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiDataProvider()),
      ],
      child: const ExecutiveApp(),
    ),
  );
}

class ExecutiveApp extends StatelessWidget {
  const ExecutiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Executive App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
