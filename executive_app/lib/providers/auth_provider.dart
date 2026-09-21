// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool isAuthenticated = false;
  Map<String, dynamic>? user;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        user = json.decode(userDataStr);
      }
      isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<String?> login(String identifier, String role) async {
    try {
      final body = role == 'executive' 
          ? {'employeeId': identifier, 'role': role}
          : {'mobile': identifier, 'role': role};
      final res = await _api.post('/login', body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', res['token']);
      user = res['user'];
      await prefs.setString('user_data', json.encode(user));
      isAuthenticated = true;
      notifyListeners();
      return null;
    } catch (e) {
      print(e);
      return e.toString().replaceFirst('Exception: API Error: ', '');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    isAuthenticated = false;
    user = null;
    notifyListeners();
  }

  void updateStatus(String status) async {
    if (user != null) {
      user!['status'] = status;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(user));
      notifyListeners();
    }
  }
}
