// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiDataProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  bool isLoading = false;
  List<dynamic> bookings = [];

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
  Future<bool> assignExecutive(int bookingId, int execId) async {
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
  Future<void> fetchExecutiveTasks() async {
    isLoading = true;
    notifyListeners();
    try {
      bookings = await _api.get('/executive/tasks');
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }

  // Executive: Update task status
  Future<bool> updateTaskStatus(int bookingId, String status, String finalBill) async {
    try {
      await _api.patch('/executive/tasks/$bookingId/status', {
        'status': status,
        'finalBill': finalBill,
      });
      await fetchExecutiveTasks();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
