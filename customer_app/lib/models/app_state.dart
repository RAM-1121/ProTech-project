import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
class Order {
  final String orderId;
  final String serviceName;
  String status;
  String executiveName;
  String executivePhone;
  String? executiveCoordinates;
  int? rating;

  Order({
    required this.orderId,
    required this.serviceName,
    this.status = 'Awaiting for Approval from Admin',
    this.executiveName = 'Pending',
    this.executivePhone = 'N/A',
    this.executiveCoordinates,
    this.rating,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'serviceName': serviceName,
    'status': status,
    'executiveName': executiveName,
    'executivePhone': executivePhone,
    'executiveCoordinates': executiveCoordinates,
    'rating': rating,
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    orderId: json['orderId'],
    serviceName: json['serviceName'],
    status: json['status'],
    executiveName: json['executiveName'],
    executivePhone: json['executivePhone'],
    executiveCoordinates: json['executiveCoordinates'],
    rating: json['rating'],
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
    _initSocket();
  }

  io.Socket? _socket;

  void _initSocket() {
    if (_socket != null) return;
    _socket = io.io(_apiBaseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .build()
    );
    _socket!.onConnect((_) {
      debugPrint('Customer App Connected to WebSocket');
    });
    _socket!.on('update_received', (data) {
      debugPrint('Customer App Update received: $data');
      fetchOrdersFromServer();
    });
  }

  String get _apiBaseUrl {
    return 'http://localhost:3000';
  }

  String get apiBaseUrl => _apiBaseUrl;

  Future<String> addOrder(String prefix, String serviceName) async {
    final random = Random();
    final uniqueId = List.generate(5, (_) => random.nextInt(10)).join('');
    final orderId = '$prefix-$uniqueId';

    final newOrder = Order(orderId: orderId, serviceName: serviceName);
    
    try {
      await loadProfile(); // ensure the profile is fully loaded from local storage
      final profile = profileNotifier.value;
      
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/bookings'),
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

  int? getOrderRating(String orderId) {
    return _orderRatings[orderId];
  }

  Future<void> setOrderRating(String orderId, int rating) async {
    _orderRatings[orderId] = rating;
    if (currentMobileNumber.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${currentMobileNumber}_rating_$orderId', rating);
  }

  final Map<String, int> _orderRatings = {};

  Future<void> loadOrders() async {
    if (currentMobileNumber.isEmpty) return;
    
    // First load from local storage
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('${currentMobileNumber}_orders');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      ordersNotifier.value = decodedData.map((json) => Order.fromJson(json)).toList();
      
      // Load ratings for existing orders
      for (final order in ordersNotifier.value) {
        final rating = prefs.getInt('${currentMobileNumber}_rating_${order.orderId}');
        if (rating != null) {
          _orderRatings[order.orderId] = rating;
        }
      }
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
        Uri.parse('$_apiBaseUrl/api/bookings?customerMobile=$currentMobileNumber'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decodedData = jsonDecode(response.body);
        
        List<dynamic> serverOrders = [];
        if (decodedData is List) {
          serverOrders = decodedData;
        } else if (decodedData is Map && decodedData['data'] is List) {
          serverOrders = decodedData['data'];
        }

        final List<Order> updatedList = serverOrders.map((serverOrder) {
          final nextJsStatus = serverOrder['status']?.toString().toUpperCase();
          final assignedEmployee = serverOrder['assignedEmployee'];
            
            // Map Next.js status to Flutter UI status
            String uiStatus = 'Your Complaint is Pending';
            if (nextJsStatus == 'ASSIGNED') {
              uiStatus = 'Assign to Executive Person';
            } else if (nextJsStatus == 'ACCEPTED') {
              uiStatus = 'Executive Person Is On The Way';
            } else if (nextJsStatus == 'IN_PROGRESS') {
              uiStatus = 'Executive Person Is On The Way'; // fallback
            } else if (nextJsStatus == 'PENDING' || nextJsStatus == 'EXECUTIVE_PENDING') {
              uiStatus = 'Your Complaint is Pending';
            } else if (nextJsStatus == 'PAYMENT PENDING') {
              uiStatus = 'Payment Pending';
            } else if (nextJsStatus == 'COMPLETED' || nextJsStatus == 'COMPLAINT CLOSED THANK YOU FOR CHOOSING PROTECH COOLING SOLUTIONS') {
              uiStatus = 'Complaint Closed Thank You For choosing Protech Cooling Solutions';
            } else if (nextJsStatus == 'CANCELLED') {
              uiStatus = 'Your complaint deleted by Protech Cooling solutions';
            } else if (nextJsStatus == 'Deleted By ADMIN' || nextJsStatus == 'DELETED BY ADMIN') {
              uiStatus = 'Deleted By ADMIN';
            }
            
            String? execCoords;
            if (assignedEmployee != null && assignedEmployee['currentLocation'] != null) {
              final coords = assignedEmployee['currentLocation']['coordinates'];
              if (coords != null && coords.length >= 2) {
                // PostGIS uses [lng, lat]
                execCoords = '${coords[1]},${coords[0]}';
              }
            }

            return Order(
              orderId: serverOrder['orderId']?.toString() ?? serverOrder['workOrderId']?.toString() ?? serverOrder['id']?.toString() ?? '',
              serviceName: serverOrder['serviceName']?.toString() ?? serverOrder['complaintType']?.toString() ?? '',
              status: uiStatus,
              executiveName: assignedEmployee != null ? assignedEmployee['name'] : 'Pending',
              executivePhone: assignedEmployee != null ? assignedEmployee['mobile'] : 'N/A',
              executiveCoordinates: execCoords,
              rating: serverOrder['rating'] != null ? int.tryParse(serverOrder['rating'].toString()) : null,
            );
          }).toList();
          
          ordersNotifier.value = updatedList;
          await _saveOrders(updatedList);
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
            updatedList[i].status = 'Assign to Executive Person';
            updatedList[i].executiveName = 'John Doe';
            updatedList[i].executivePhone = '+91 9876543210';
            break;
          case 'Assign to Executive Person':
            updatedList[i].status = 'Executive Person Is On The Way';
            break;
          case 'Executive Person Is On The Way':
            updatedList[i].status = 'Complaint Closed Thank You For choosing Protech Cooling Solutions';
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newProfile.name);
    await prefs.setString('user_mobile', newProfile.mobile);
    await prefs.setString('user_email', newProfile.email);
    await prefs.setString('full_address', newProfile.address);
    // address_flat, street, city, pincode are already saved individually by the screens
    // We shouldn't overwrite address_flat with the full concatenated address.
    if (newProfile.mapLocation.isNotEmpty && newProfile.mapLocation.contains(',')) {
      try {
        final parts = newProfile.mapLocation.split(',');
        await prefs.setDouble('user_lat', double.parse(parts[0]));
        await prefs.setDouble('user_lng', double.parse(parts[1]));
      } catch (e) {
        debugPrint('Error parsing coordinates: $e');
      }
    }
    await prefs.setString('profile_picture', newProfile.profilePicturePath);
    await prefs.setBool('is_registered', true);
  }

  Future<bool> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRegistered = prefs.getBool('is_registered') ?? false;
    
    if (hasRegistered) {
      final name = prefs.getString('user_name') ?? '';
      final mobile = prefs.getString('user_mobile') ?? currentMobileNumber;
      final email = prefs.getString('user_email') ?? '';
      
      final flat = prefs.getString('address_flat') ?? '';
      final street = prefs.getString('address_street') ?? '';
      final city = prefs.getString('address_city') ?? '';
      final pin = prefs.getString('address_pincode') ?? '';
      
      final parts = [flat, street, city, pin].where((e) => e.isNotEmpty);
      final uniqueTokens = <String>{};
      for (final p in parts) {
        uniqueTokens.addAll(p.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
      String fullAddress = uniqueTokens.join(', ');
      
      // Fallback to the saved full_address if individual components aren't set
      if (fullAddress.isEmpty) {
        fullAddress = prefs.getString('full_address') ?? '';
      }
      
      final lat = prefs.getDouble('user_lat');
      final lng = prefs.getDouble('user_lng');
      final mapLocation = (lat != null && lng != null) ? '$lat,$lng' : '';
      
      final picPath = prefs.getString('profile_picture') ?? '';
      
      profileNotifier.value = UserProfile(
        name: name,
        mobile: mobile.isNotEmpty ? mobile : currentMobileNumber,
        email: email,
        address: fullAddress,
        mapLocation: mapLocation,
        profilePicturePath: picPath,
      );
    } else {
      profileNotifier.value = UserProfile(mobile: currentMobileNumber); // Pre-fill mobile
    }
    
    return hasRegistered;
  }
}
