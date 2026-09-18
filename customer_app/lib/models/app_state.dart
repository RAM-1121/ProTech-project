import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Order {
  final String orderId;
  final String serviceName;
  String status;
  String executiveName;
  String executivePhone;

  Order({
    required this.orderId,
    required this.serviceName,
    this.status = 'Awaiting for Approval from Admin',
    this.executiveName = 'Pending',
    this.executivePhone = 'N/A',
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'serviceName': serviceName,
    'status': status,
    'executiveName': executiveName,
    'executivePhone': executivePhone,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    orderId: json['orderId'],
    serviceName: json['serviceName'],
    status: json['status'],
    executiveName: json['executiveName'],
    executivePhone: json['executivePhone'],
  );
}

class UserProfile {
  String name;
  String mobile;
  String email;
  String address;
  String mapLocation;
  String profilePicturePath;

  UserProfile({
    this.name = '',
    this.mobile = '',
    this.email = '',
    this.address = '',
    this.mapLocation = '',
    this.profilePicturePath = '',
  });
}

class AppState {
  // Singleton instance
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  String currentMobileNumber = '';

  // Orders State
  final ValueNotifier<List<Order>> ordersNotifier = ValueNotifier([]);

  // Profile State
  final ValueNotifier<UserProfile> profileNotifier = ValueNotifier(UserProfile());

  // Notifications State
  final ValueNotifier<List<String>> clearedNotificationsNotifier = ValueNotifier([]);

  void setMobileNumber(String mobile) {
    currentMobileNumber = mobile;
  }

  String get _apiBaseUrl {
    return 'http://127.0.0.1:3000';
  }

  Future<String> addOrder(String prefix, String serviceName) async {
    final random = Random();
    final uniqueId = List.generate(5, (_) => random.nextInt(10)).join('');
    final orderId = '$prefix-$uniqueId';

    final newOrder = Order(orderId: orderId, serviceName: serviceName);
    
    try {
      final profile = profileNotifier.value;
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/work-orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'serviceName': serviceName,
          'customerName': profile.name.isNotEmpty ? profile.name : 'Guest',
          'customerMobile': currentMobileNumber,
          'customerAddress': profile.address.isNotEmpty ? profile.address : 'Not provided',
          'customerCoordinates': profile.mapLocation.isNotEmpty ? profile.mapLocation : null,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Failed to create order on server: ${response.statusCode} - ${response.body}');
        // Optional: throw exception to show error to user
      } else {
        debugPrint('Successfully created order on server!');
      }
    } catch (e) {
      debugPrint('Error communicating with server: $e');
      // If we're on a real device, localhost won't work. Catching here prevents crashing.
    }

    // Create a new list to trigger the notifier
    final updatedList = [...ordersNotifier.value, newOrder];
    ordersNotifier.value = updatedList;
    
    await _saveOrders(updatedList);
    return orderId;
  }

  Future<void> clearNotification(String orderId) async {
    final updatedList = [...clearedNotificationsNotifier.value, orderId];
    clearedNotificationsNotifier.value = updatedList;
    await _saveClearedNotifications(updatedList);
  }

  Future<void> clearAllNotifications(List<String> orderIds) async {
    final updatedList = [...clearedNotificationsNotifier.value, ...orderIds];
    clearedNotificationsNotifier.value = updatedList.toSet().toList();
    await _saveClearedNotifications(clearedNotificationsNotifier.value);
  }

  Future<void> _saveClearedNotifications(List<String> ids) async {
    if (currentMobileNumber.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${currentMobileNumber}_cleared_notifs', ids);
  }

  Future<void> _saveOrders(List<Order> orders) async {
    if (currentMobileNumber.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString('${currentMobileNumber}_orders', encodedData);
  }

  Future<void> loadOrders() async {
    if (currentMobileNumber.isEmpty) return;
    
    // First load from local storage
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('${currentMobileNumber}_orders');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      ordersNotifier.value = decodedData.map((json) => Order.fromJson(json)).toList();
    } else {
      ordersNotifier.value = []; // clear for new user
    }
    
    final List<String>? clearedNotifs = prefs.getStringList('${currentMobileNumber}_cleared_notifs');
    if (clearedNotifs != null) {
      clearedNotificationsNotifier.value = clearedNotifs;
    } else {
      clearedNotificationsNotifier.value = [];
    }

    
    // Then sync with server in background
    fetchOrdersFromServer();
  }

  Future<void> fetchOrdersFromServer() async {
    if (currentMobileNumber.isEmpty) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/work-orders?customerMobile=$currentMobileNumber'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> serverOrders = responseData['data'];
          
          final List<Order> updatedList = serverOrders.map((serverOrder) {
            final nextJsStatus = serverOrder['status'];
            final assignedEmployee = serverOrder['assignedEmployee'];
            
            // Map Next.js status to Flutter UI status
            String uiStatus = 'Awaiting for Approval from Admin';
            if (nextJsStatus == 'ASSIGNED') {
              uiStatus = 'Assign to Executive';
            } else if (nextJsStatus == 'ACCEPTED') {
              uiStatus = 'On the Way';
            } else if (nextJsStatus == 'IN_PROGRESS') {
              uiStatus = 'In Progress';
            } else if (nextJsStatus == 'PENDING') {
              uiStatus = 'Pending';
            } else if (nextJsStatus == 'COMPLETED') {
              uiStatus = 'Closed';
            } else if (nextJsStatus == 'CANCELLED') {
              uiStatus = 'Your complaint deleted by Protech Cooling solutions';
            }
            
            return Order(
              orderId: serverOrder['workOrderId'],
              serviceName: serverOrder['complaintType'],
              status: uiStatus,
              executiveName: assignedEmployee != null ? assignedEmployee['name'] : 'Pending',
              executivePhone: assignedEmployee != null ? assignedEmployee['mobile'] : 'N/A',
            );
          }).toList();
          
          ordersNotifier.value = updatedList;
          await _saveOrders(updatedList);
        }
      } else {
        debugPrint('Failed to fetch orders from server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching from server: $e');
    }
  }

  Future<void> advanceOrderStatus(String orderId) async {
    final updatedList = List<Order>.from(ordersNotifier.value);
    for (int i = 0; i < updatedList.length; i++) {
      if (updatedList[i].orderId == orderId) {
        switch (updatedList[i].status) {
          case 'Awaiting for Approval from Admin':
            updatedList[i].status = 'Assign to Executive';
            updatedList[i].executiveName = 'John Doe';
            updatedList[i].executivePhone = '+91 9876543210';
            break;
          case 'Assign to Executive':
            updatedList[i].status = 'On the Way';
            break;
          case 'On the Way':
            updatedList[i].status = 'Closed';
            break;
        }
        break;
      }
    }
    ordersNotifier.value = updatedList;
    await _saveOrders(updatedList);
  }

  Future<void> updateProfile(UserProfile newProfile) async {
    profileNotifier.value = newProfile;
    if (currentMobileNumber.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${currentMobileNumber}_profile_name', newProfile.name);
    await prefs.setString('${currentMobileNumber}_profile_mobile', newProfile.mobile);
    await prefs.setString('${currentMobileNumber}_profile_email', newProfile.email);
    await prefs.setString('${currentMobileNumber}_profile_address', newProfile.address);
    await prefs.setString('${currentMobileNumber}_profile_mapLocation', newProfile.mapLocation);
    await prefs.setString('${currentMobileNumber}_profile_picture', newProfile.profilePicturePath);
    await prefs.setBool('${currentMobileNumber}_hasRegisteredProfile', true);
  }

  Future<bool> loadProfile() async {
    if (currentMobileNumber.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final hasRegistered = prefs.getBool('${currentMobileNumber}_hasRegisteredProfile') ?? false;
    
    if (hasRegistered) {
      final name = prefs.getString('${currentMobileNumber}_profile_name') ?? '';
      final mobile = prefs.getString('${currentMobileNumber}_profile_mobile') ?? '';
      final email = prefs.getString('${currentMobileNumber}_profile_email') ?? '';
      final address = prefs.getString('${currentMobileNumber}_profile_address') ?? '';
      final mapLocation = prefs.getString('${currentMobileNumber}_profile_mapLocation') ?? '';
      final picPath = prefs.getString('${currentMobileNumber}_profile_picture') ?? '';
      
      profileNotifier.value = UserProfile(
        name: name,
        mobile: mobile,
        email: email,
        address: address,
        mapLocation: mapLocation,
        profilePicturePath: picPath,
      );
    } else {
      profileNotifier.value = UserProfile(mobile: currentMobileNumber); // Pre-fill mobile
    }
    
    return hasRegistered;
  }
}
