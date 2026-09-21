// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final Color color;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class ApiDataProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool isLoading = false;
  List<dynamic> bookings = [];
  Map<String, dynamic>? myProfile;
  List<NotificationItem> notifications = [];

  void addNotification(NotificationItem item) {
    notifications.insert(0, item);
    notifyListeners();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }
  
  void removeNotification(String id) {
    notifications.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> fetchMyProfile(String employeeId) async {
    try {
      myProfile = await _api.get('/users/executives/profile/$employeeId');
      notifyListeners();
    } catch (e) {
      print('Failed to fetch profile: $e');
    }
  }

  void updateProfileLocally(Map<String, dynamic> newProfile) {
    if (myProfile != null && myProfile!['employeeId'] == newProfile['employeeId']) {
      myProfile = newProfile;
      notifyListeners();
    }
  }

  // Customer: Fetch my bookings
  Future<void> fetchCustomerBookings() async {
    isLoading = true;
    notifyListeners();
    try {
      bookings = await _api.get('/customer/bookings');
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }

  // Customer: Create booking
  Future<bool> createBooking(String type, String date, String address) async {
    try {
      await _api.post('/customer/bookings', {
        'type': type,
        'date': date,
        'address': address,
      });
      await fetchCustomerBookings();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Admin: Fetch all bookings
  Future<void> fetchAdminBookings() async {
    isLoading = true;
    notifyListeners();
    try {
      bookings = await _api.get('/admin/bookings');
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }

  // Admin: Assign booking
  Future<bool> assignExecutive(String bookingId, int execId) async {
    try {
      await _api.patch('/admin/bookings/$bookingId/assign', {
        'assignedExecutiveId': execId,
      });
      await fetchAdminBookings();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Executive: Fetch my tasks
  Future<void> fetchExecutiveTasks({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      notifyListeners();
    }
    try {
      bookings = await _api.get('/executive/tasks');
    } catch (e) {
      print(e);
    }
    if (!silent) {
      isLoading = false;
    }
    // Always notify listeners at the end so the UI rebuilds with new data
    notifyListeners();
  } 
  
  // Executive: Update task status
  
  Future<Map<String, dynamic>> fetchWalletDetails() async {
    final response = await _api.get('/users/executive/wallet');
    return response;
  }

  Future<void> submitApproval(Map<String, dynamic> payload) async {
    await _api.post('/approvals', payload);
  }

  Future<void> redeemPoints(int amount) async {
    await _api.post('/users/executive/wallet/redeem', { 'amount': amount });
  }

  Future<List<dynamic>> fetchPlans() async {
    try {
      final res = await _api.get('/plans');
      return res as List;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<dynamic>> fetchCoupons() async {
    try {
      final res = await _api.get('/plans/coupons');
      return res as List;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<String?> fetchCompanyUpiId() async {
    try {
      final res = await _api.get('/payments/upi-id');
      return res['upiId']?.toString();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> updateTaskStatus({
    required String bookingId,
    required String status,
    String? pendingReason,
    String? finalBill,
    String? planId,
    String? couponId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status,
      };
      if (pendingReason != null) payload['pendingReason'] = pendingReason;
      if (finalBill != null) payload['finalBill'] = finalBill;
      if (planId != null) payload['planId'] = planId;
      if (couponId != null) payload['couponId'] = couponId;

      await _api.patch('/executive/tasks/$bookingId/status', payload);
      await fetchExecutiveTasks();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
