import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWalkthrough = prefs.getBool('hasSeenWalkthrough') ?? false;
    final token = prefs.getString('jwt_token');
    final isRegistered = prefs.getBool('is_registered') ?? false;

    if (!mounted) return;

    if (!hasSeenWalkthrough) {
      Navigator.pushReplacementNamed(context, '/walkthrough');
    } else if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else if (!isRegistered) {
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      final savedMobile = prefs.getString('saved_mobile') ?? '';
      if (savedMobile.isNotEmpty) {
        AppState().setMobileNumber(savedMobile);
      }
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
