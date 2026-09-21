import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final MaterialColor color;
  final int? targetMainIndex;
  final int? targetSubIndex;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    this.targetMainIndex,
    this.targetSubIndex,
  });
}

class NotificationBell extends StatelessWidget {
  final Function(int mainIndex, int subIndex)? onNavigate;

  const NotificationBell({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;

        return PopupMenuButton<String>(
          offset: const Offset(0, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
          elevation: 10,
          tooltip: 'Notifications',
          onSelected: (value) {
            if (value == 'clear_all') {
              notificationProvider.clearAll();
            }
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                  ]
                ),
                child: const Icon(Icons.notifications_outlined, size: 28, color: Color(0xFF1E293B)),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(notifications.isEmpty ? 5 : 4),
                  constraints: BoxConstraints(
                    minWidth: notifications.isEmpty ? 10 : 20,
                    minHeight: notifications.isEmpty ? 10 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: notifications.isEmpty
                      ? const SizedBox.shrink()
                      : Center(
                          child: Text(
                            '${notifications.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              )
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, setStateMenu) {
                  // Important: we need to use the current provider's notifications here
                  final currentNotifications = Provider.of<NotificationProvider>(context).notifications;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            if (currentNotifications.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, 'clear_all');
                                },
                                child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      if (currentNotifications.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No new notifications', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: currentNotifications
                                  .map((n) => _buildNotificationCapsule(context, n, notificationProvider, setStateMenu))
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCapsule(BuildContext context, NotificationItem n, NotificationProvider provider, StateSetter setStateMenu) {
    return InkWell(
      onTap: () {
        if (n.targetMainIndex != null && onNavigate != null) {
          Navigator.pop(context); // Close popup
          onNavigate!(n.targetMainIndex!, n.targetSubIndex ?? 0);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: n.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: n.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 14, color: n.color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: TextStyle(fontWeight: FontWeight.bold, color: n.color, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(n.subtitle, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () {
                  setStateMenu(() {
                    provider.removeNotification(n.id);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
