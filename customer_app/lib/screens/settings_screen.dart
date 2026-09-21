import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLocationEnabled = false;
  bool _isCameraEnabled = false;
  bool _isNotificationEnabled = false;
  bool _isBiometricsEnabled = false;
  bool _showItems = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionStates();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showItems = true);
      }
    });
  }

  Future<void> _loadPermissionStates() async {
    final prefs = await SharedPreferences.getInstance();
    
    final locStatus = await Permission.location.status;
    final camStatus = await Permission.camera.status;
    final notifStatus = await Permission.notification.status;

    // We consider it enabled ONLY if both the OS allows it AND our local override hasn't disabled it.
    setState(() {
      _isLocationEnabled = locStatus.isGranted && (prefs.getBool('app_loc_enabled') ?? true);
      _isCameraEnabled = camStatus.isGranted && (prefs.getBool('app_cam_enabled') ?? true);
      _isNotificationEnabled = notifStatus.isGranted && (prefs.getBool('app_notif_enabled') ?? true);
      _isBiometricsEnabled = prefs.getBool('use_biometrics') ?? false;
    });
  }

  Future<void> _handlePermissionToggle(
    Permission permission,
    bool newValue,
    String localKey,
    Function(bool) updateState,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (!newValue) {
      // User wants to turn it OFF. We can't revoke OS permission, so we set a local override.
      await prefs.setBool(localKey, false);
      updateState(false);
      return;
    }

    // User wants to turn it ON.
    var status = await permission.status;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showSettingsRedirectDialog();
      return;
    }

    if (status.isDenied) {
      status = await permission.request();
      if (status.isPermanentlyDenied) {
        _showSettingsRedirectDialog();
        return;
      }
    }

    if (status.isGranted) {
      await prefs.setBool(localKey, true);
      updateState(true);
    } else {
      // They denied it this time.
      updateState(false);
    }
  }

  void _showSettingsRedirectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('This permission has been permanently denied. You must enable it in your device settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings & Permissions',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryDark),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader('App Permissions'),
          const SizedBox(height: 10),
          _AnimatedSettingCapsule(
            title: 'Location Services',
            subtitle: 'Required for map and tracking',
            icon: Icons.location_on,
            iconColor: Colors.blueAccent,
            value: _isLocationEnabled,
            onChanged: (val) {
              _handlePermissionToggle(
                Permission.location,
                val,
                'app_loc_enabled',
                (newVal) => setState(() => _isLocationEnabled = newVal),
              );
            },
            show: _showItems,
            index: 0,
          ),
          const SizedBox(height: 16),
          _AnimatedSettingCapsule(
            title: 'Camera & Photos',
            subtitle: 'Required to update profile picture',
            icon: Icons.camera_alt,
            iconColor: Colors.purpleAccent,
            value: _isCameraEnabled,
            onChanged: (val) {
              _handlePermissionToggle(
                Permission.camera,
                val,
                'app_cam_enabled',
                (newVal) => setState(() => _isCameraEnabled = newVal),
              );
            },
            show: _showItems,
            index: 1,
          ),
          const SizedBox(height: 16),
          _AnimatedSettingCapsule(
            title: 'Push Notifications',
            subtitle: 'Get updates on your bookings',
            icon: Icons.notifications_active,
            iconColor: Colors.orangeAccent,
            value: _isNotificationEnabled,
            onChanged: (val) {
              _handlePermissionToggle(
                Permission.notification,
                val,
                'app_notif_enabled',
                (newVal) => setState(() => _isNotificationEnabled = newVal),
              );
            },
            show: _showItems,
            index: 2,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Security'),
          const SizedBox(height: 10),
          _AnimatedSettingCapsule(
            title: 'Face ID / PIN (Instant Login)',
            subtitle: 'Login securely without OTP',
            icon: Icons.security,
            iconColor: Colors.teal,
            value: _isBiometricsEnabled,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('use_biometrics', val);
              setState(() {
                _isBiometricsEnabled = val;
              });
            },
            show: _showItems,
            index: 3,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _showItems ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        offset: _showItems ? Offset.zero : const Offset(0.0, 0.2),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryMid,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSettingCapsule extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool show;
  final int index;

  const _AnimatedSettingCapsule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
    required this.show,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: show ? 1.0 : 0.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: AppColors.primaryMid,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
