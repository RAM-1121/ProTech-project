// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/app_state.dart';

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

  Future<bool> sendOtp(String mobile) async {
    try {
      await _api.post('/auth/send-otp', {'phone': mobile});
      return true;
    } catch (e) {
      print('Send OTP Error: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    try {
      final res = await _api.post('/auth/verify-otp', {'phone': mobile, 'otp': otp});
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', res['token']);
        isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Verify OTP Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Preserve fast login information
    final savedMobile = prefs.getString('saved_mobile');
    final useBiometrics = prefs.getBool('use_biometrics');
    final hasSeenWalkthrough = prefs.getBool('hasSeenWalkthrough');
    
    // Clear all local user data to prevent data leakage between different accounts
    await prefs.clear();
    
    // Restore fast login information and app state preferences
    if (savedMobile != null) {
      await prefs.setString('saved_mobile', savedMobile);
    }
    if (useBiometrics != null) {
      await prefs.setBool('use_biometrics', useBiometrics);
    }
    if (hasSeenWalkthrough != null) {
      await prefs.setBool('hasSeenWalkthrough', hasSeenWalkthrough);
    }

    // Reset global AppState
    AppState().profileNotifier.value = UserProfile();
    AppState().ordersNotifier.value = [];
    AppState().currentMobileNumber = '';

    isAuthenticated = false;
    user = null;
    notifyListeners();
  }
}
