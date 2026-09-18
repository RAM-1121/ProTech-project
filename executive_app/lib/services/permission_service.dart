import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  // Requests
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestBackgroundRefreshPermission() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  // Checks
  Future<bool> checkCameraPermission() async {
    return await Permission.camera.status.isGranted;
  }

  Future<bool> checkGalleryPermission() async {
    final photosGranted = await Permission.photos.status.isGranted;
    final storageGranted = await Permission.storage.status.isGranted;
    return photosGranted || storageGranted;
  }

  Future<bool> checkLocationPermission() async {
    return await Permission.locationWhenInUse.status.isGranted || await Permission.locationAlways.status.isGranted;
  }

  Future<bool> checkNotificationPermission() async {
    return await Permission.notification.status.isGranted;
  }

  Future<bool> checkBackgroundRefreshPermission() async {
    return await Permission.ignoreBatteryOptimizations.status.isGranted;
  }

  // Open Settings
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
