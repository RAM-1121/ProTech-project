import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
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

  Widget _buildPermissionTile(String title, String subtitle, bool isGranted, IconData icon, ThemeData theme) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: isGranted,
        activeThumbColor: theme.colorScheme.primary,
        onChanged: (val) => _handleToggle(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'App Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          _buildPermissionTile(
            'Camera',
            'Required for taking photos of issues.',
            _cameraGranted,
            Icons.camera_alt_outlined,
            theme,
          ),
          const Divider(),
          _buildPermissionTile(
            'Gallery',
            'Required for selecting photos.',
            _galleryGranted,
            Icons.photo_library_outlined,
            theme,
          ),
          const Divider(),
          _buildPermissionTile(
            'Location',
            'Required for tracking your tasks.',
            _locationGranted,
            Icons.location_on_outlined,
            theme,
          ),
          const Divider(),
          _buildPermissionTile(
            'Notifications',
            'Required for new task alerts.',
            _notificationGranted,
            Icons.notifications_none,
            theme,
          ),
          const Divider(),
          _buildPermissionTile(
            'Background Refresh',
            'Required for background sync.',
            _backgroundGranted,
            Icons.refresh_outlined,
            theme,
          ),
          const SizedBox(height: 100), // padding for bottom nav
        ],
      ),
    );
  }
}
