// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool isAuthenticated = false;
  Map<String, dynamic>? user;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String mobile, String role) async {
    try {
      final res = await _api.post('/login', {'mobile': mobile, 'role': role});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', res['token']);
      user = res['user'];
      isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    isAuthenticated = false;
    user = null;
    notifyListeners();
  }
}
