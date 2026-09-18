import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';

class SettingsTabScreen extends StatefulWidget {
  const SettingsTabScreen({super.key});

  @override
  State<SettingsTabScreen> createState() => _SettingsTabScreenState();
}

class _SettingsTabScreenState extends State<SettingsTabScreen> with WidgetsBindingObserver {
  bool _cameraGranted = false;
  bool _galleryGranted = false;
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _backgroundGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final ps = PermissionService();
    final cam = await ps.checkCameraPermission();
    final gal = await ps.checkGalleryPermission();
    final loc = await ps.checkLocationPermission();
    final notif = await ps.checkNotificationPermission();
    final bg = await ps.checkBackgroundRefreshPermission();

    if (mounted) {
      setState(() {
        _cameraGranted = cam;
        _galleryGranted = gal;
        _locationGranted = loc;
        _notificationGranted = notif;
        _backgroundGranted = bg;
      });
    }
  }

  void _handleToggle(String permissionName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change $permissionName Permission'),
        content: Text('To change the $permissionName permission, please go to your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              PermissionService().openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(String title, String subtitle, bool isGranted, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryMid),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isGranted,
        activeThumbColor: AppColors.primaryMid,
        onChanged: (val) => _handleToggle(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'App Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
          _buildPermissionTile(
            'Camera',
            'Required for taking photos of issues.',
            _cameraGranted,
            Icons.camera_alt_outlined,
          ),
          const Divider(),
          _buildPermissionTile(
            'Gallery',
            'Required for selecting photos.',
            _galleryGranted,
            Icons.photo_library_outlined,
          ),
          const Divider(),
          _buildPermissionTile(
            'Location',
            'Required for tracking technicians.',
            _locationGranted,
            Icons.location_on_outlined,
          ),
          const Divider(),
          _buildPermissionTile(
            'Notifications',
            'Required for updates on your bookings.',
            _notificationGranted,
            Icons.notifications_none,
          ),
          const Divider(),
          _buildPermissionTile(
            'Background Refresh',
            'Required for background data sync.',
            _backgroundGranted,
            Icons.refresh_outlined,
          ),
        ],
      ),
    );
  }
}
