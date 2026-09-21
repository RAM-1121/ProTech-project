import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/api_data_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApiDataProvider()),
      ],
      child: ExecutiveApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}

class ExecutiveApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const ExecutiveApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Executive App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A00E0),
          primary: const Color(0xFF4A00E0),
          secondary: const Color(0xFF8E2DE2),
          surface: const Color(0xFFF8F9FA),
          onSurface: const Color(0xFF1E1E2C),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
          titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          titleSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
          bodyLarge: TextStyle(color: Color(0xFF800020), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF800020), fontSize: 14),
          bodySmall: TextStyle(color: Color(0xFF800020), fontSize: 12),
          labelLarge: TextStyle(color: Color(0xFF800020), fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E1E2C),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E1E2C),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: const Color(0xFF4A00E0).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFF4A00E0),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      initialRoute: hasSeenOnboarding ? '/login' : '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
