import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Map<String, dynamic>> _permissionsList = [
    {
      'title': 'Camera',
      'icon': Icons.camera_alt,
      'permission': Permission.camera,
      'isGranted': false,
      'color': Colors.blueAccent,
    },
    {
      'title': 'Location',
      'icon': Icons.location_on,
      'permission': Permission.location,
      'isGranted': false,
      'color': Colors.green,
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications,
      'permission': Permission.notification,
      'isGranted': false,
      'color': Colors.orange,
    },
    {
      'title': 'Media / Storage',
      'icon': Icons.photo_library,
      'permission': Permission.storage,
      'isGranted': false,
      'color': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    for (var item in _permissionsList) {
      final perm = item['permission'] as Permission;
      try {
        final status = await perm.status;
        setState(() {
          item['isGranted'] = status.isGranted;
        });
      } catch (e) {
        // web fallback
        setState(() {
          item['isGranted'] = true; 
        });
      }
    }
  }

  Future<void> _togglePermission(int index, bool newValue) async {
    final item = _permissionsList[index];
    final perm = item['permission'] as Permission;
    
    if (newValue) {
      try {
        final status = await perm.request();
        setState(() {
          item['isGranted'] = status.isGranted;
        });
        if (status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Permission permanently denied. Please enable in OS settings.'),
                action: SnackBarAction(label: 'Settings', onPressed: () => openAppSettings()),
              ),
            );
          }
        }
      } catch (e) {
        // Mock success on web since permission_handler throws on web
        setState(() {
          item['isGranted'] = newValue;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Cannot revoke ${item['title']} permission from within the app. Please change it in your device settings.'),
            action: SnackBarAction(label: 'Settings', onPressed: () => openAppSettings()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          itemCount: _permissionsList.length,
          itemBuilder: (BuildContext context, int index) {
            final item = _permissionsList[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildPermissionCapsule(index, item),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionCapsule(int index, Map<String, dynamic> item) {
    final bool isGranted = item['isGranted'];
    final Color color = item['color'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isGranted ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(
          color: isGranted ? color.withValues(alpha: 0.5) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isGranted ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'],
                  color: isGranted ? color : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isGranted ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGranted ? 'Granted' : 'Denied',
                      style: TextStyle(
                        fontSize: 12,
                        color: isGranted ? color : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isGranted,
                activeTrackColor: color.withValues(alpha: 0.5),
                activeThumbColor: color,
                onChanged: (val) => _togglePermission(index, val),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
