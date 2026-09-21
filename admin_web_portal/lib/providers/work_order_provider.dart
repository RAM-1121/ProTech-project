import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class WorkOrder {
  final String id;
  final String title;
  String status;
  String? assignedEmployeeName;
  String? customerName;
  String? customerMobile;
  String? customerAddress;
  String? customerCoordinates;
  String? pendingReason;
  String? planName;
  String? couponCode;
  String? finalBill;
  int? rating;
  int? rewardPoints;
  WorkOrder({
    required this.id, 
    required this.title, 
    required this.status, 
    this.assignedEmployeeName,
    this.customerName,
    this.customerMobile,
    this.customerAddress,
    this.customerCoordinates,
    this.pendingReason,
    this.planName,
    this.couponCode,
    this.finalBill,
    this.rating,
    this.rewardPoints,
  });
}

class WorkOrderProvider with ChangeNotifier {
  final ApiService apiService;
  final WebSocketService webSocketService;

  List<WorkOrder> workOrders = [];
  bool isLoading = false;
  String? error;

  WorkOrderProvider({required this.apiService, required this.webSocketService}) {
    _init();
  }

  void _init() {
    fetchWorkOrders();

    webSocketService.addListener((data) {
      if (data != null && data['type'] != null) {
        // We can either selectively update or just refetch everything
        fetchWorkOrders();
      }
    });
  }

  Future<void> fetchWorkOrders({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      final response = await apiService.get('/bookings');
      if (response is List) {
        workOrders = response
            .where((data) => data['hiddenFromAdmin'] != true)
            .map((data) {
          return WorkOrder(
            id: data['orderId']?.toString() ?? data['id']?.toString() ?? '',
            title: data['serviceName']?.toString() ?? data['title']?.toString() ?? 'Work Order',
            status: data['status']?.toString() ?? 'Pending',
            assignedEmployeeName: data['assignedEmployee']?['name']?.toString(),
            customerName: data['customerName']?.toString(),
            customerMobile: data['customerMobile']?.toString(),
            customerAddress: data['customerAddress']?.toString(),
            customerCoordinates: data['customerCoordinates']?.toString(),
            pendingReason: data['pendingReason']?.toString(),
            planName: data['planName']?.toString(),
            couponCode: data['couponCode']?.toString(),
            finalBill: data['finalBill']?.toString(),
            rating: data['rating'] != null ? int.tryParse(data['rating'].toString()) : null,
            rewardPoints: data['rewardPoints'] != null ? int.tryParse(data['rewardPoints'].toString()) : null,
          );
        }).toList();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (!silent) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> updateWorkOrderStatus(String id, String status, [Map<String, dynamic>? assignedEmployee]) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (assignedEmployee != null) {
        body['assignedEmployee'] = assignedEmployee;
      }
      await apiService.patch('/bookings/$id/status', body);
      // Immediately refetch silently to update UI state instantly
      await fetchWorkOrders(silent: true);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteWorkOrder(String id) async {
    try {
      await apiService.delete('/bookings/$id');
      // Immediately refetch silently to update UI state instantly
      await fetchWorkOrders(silent: true);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
