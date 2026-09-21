import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/api_data_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/customer_main_screen.dart';
import 'screens/root_screen.dart';
import 'screens/walkthrough_screen.dart';
import 'screens/registration_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiDataProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      initialRoute: '/',
      routes: {
        '/': (context) => const RootScreen(),
        '/walkthrough': (context) => const WalkthroughScreen(),
        '/login': (context) => const AuthScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/main': (context) => const CustomerMainScreen(),
      },
    );
  }
}
