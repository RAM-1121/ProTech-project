import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'view_profile_screen.dart';
import 'wallet_screen.dart';
import 'attendance_screen.dart';
import 'settings_screen.dart';
import '../../widgets/notification_bell.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: const [NotificationBell()],
      ),
      body: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              // Profile Picture Removed

              const SizedBox(height: 16),
              const _ActiveStatusCard(),
              _buildCapsuleMenu(
                context,
                icon: Icons.person,
                title: 'View Profile',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewProfileScreen())),
              ),
              _buildCapsuleMenu(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Wallet (Rewards)',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _buildCapsuleMenu(
                context,
                icon: Icons.event_available,
                title: 'Attendance',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
              ),
              _buildCapsuleMenu(
                context,
                icon: Icons.settings,
                title: 'Settings',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              _buildCapsuleMenu(
                context,
                icon: Icons.logout,
                title: 'Logout',
                isDestructive: true,
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleMenu(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : Colors.blueAccent;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDestructive ? Colors.red : Colors.black87)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}

class _ActiveStatusCard extends StatefulWidget {
  const _ActiveStatusCard();

  @override
  State<_ActiveStatusCard> createState() => _ActiveStatusCardState();
}

class _ActiveStatusCardState extends State<_ActiveStatusCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (consumerContext, auth, _) {
        final status = auth.user?['status'] ?? 'Offline';
        final isOnLeave = status == 'On Leave';
        final isActive = status == 'Active';
        
        final displayStatus = isOnLeave ? 'ON LEAVE' : (isActive ? 'ACTIVE' : 'OFFLINE');
        final statusColor = isOnLeave ? Colors.orange : (isActive ? Colors.green : Colors.grey);
        final statusIcon = isOnLeave ? Icons.flight_takeoff : Icons.work;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(displayStatus, style: TextStyle(fontWeight: FontWeight.w600, color: statusColor)),
            value: isActive,
            onChanged: (_isUpdating || isOnLeave) ? null : (val) async {
              setState(() { _isUpdating = true; });
              try {
                final newStatus = val ? 'Active' : 'Offline';
                final api = ApiService();
                final employeeId = auth.user?['employeeId'];
                if (employeeId == null) throw 'User data missing. Please re-login.';
                await api.patch('/users/executives/$employeeId', {
                  'status': newStatus,
                });
                auth.updateStatus(newStatus);
              } catch (e) {
                if (consumerContext.mounted) {
                  ScaffoldMessenger.of(consumerContext).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
                }
              } finally {
                if (mounted) {
                  setState(() { _isUpdating = false; });
                }
              }
            },
          ),
        );
      },
    );
  }
}
