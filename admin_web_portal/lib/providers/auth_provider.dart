// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool isAuthenticated = false;
  Map<String, dynamic>? user;

  bool get isMasterAdmin {
    final role = user?['role']?.toString().toLowerCase();
    return role == 'master admin' || role == 'master_admin';
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role = prefs.getString('role');
    final mobile = prefs.getString('mobile');
    if (token != null) {
      isAuthenticated = true;
      user = {'role': role ?? 'Master Admin', 'mobile': mobile}; // default fallback
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String mobile) async {
    try {
      // In a real app this hits an endpoint. For now we simulate success.
      // await _api.post('/auth/send-otp', {'phone': mobile});
      return true;
    } catch (e) {
      print('Send OTP Error: $e');
      return false;
    }
  }

  Future<bool> verifyOtpAndLogin(String mobile, String otp) async {
    try {
      // Hardcoded mock OTP for testing
      if (otp != '123456') {
        return false;
      }
      return await login(mobile, 'admin');
    } catch (e) {
      print('Verify OTP Error: $e');
      return false;
    }
  }

  Future<bool> login(String mobile, String role) async {
    try {
      final res = await _api.post('/login', {'mobile': mobile, 'role': role});
      final prefs = await SharedPreferences.getInstance();
      user = res['user'] ?? {'role': role, 'mobile': mobile};
      
      await prefs.setString('jwt_token', res['token']);
      await prefs.setString('role', user!['role'] ?? role);
      await prefs.setString('mobile', mobile);
      
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
    await prefs.remove('role');
    isAuthenticated = false;
    user = null;
    notifyListeners();
  }
}
