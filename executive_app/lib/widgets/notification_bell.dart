import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_data_provider.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiDataProvider>(
      builder: (context, apiDataProvider, child) {
        final notifications = apiDataProvider.notifications;

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
          elevation: 10,
          tooltip: 'Notifications',
          onSelected: (value) {
            if (value == 'clear_all') {
              apiDataProvider.clearNotifications();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
                  ]
                ),
                child: const Icon(Icons.notifications_outlined, size: 24, color: Colors.blueAccent),
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 12,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '${notifications.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, setStateMenu) {
                  final currentNotifications = Provider.of<ApiDataProvider>(context).notifications;
                  return SizedBox(
                    width: 350,
                    height: 400,
                    child: Column(
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
                                  onPressed: () => Navigator.pop(context, 'clear_all'),
                                  child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        if (currentNotifications.isEmpty)
                          const Expanded(
                            child: Center(child: Text('No new notifications', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: currentNotifications
                                    .map((n) => _buildNotificationCapsule(context, n, apiDataProvider, setStateMenu))
                                    .toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCapsule(BuildContext context, NotificationItem n, ApiDataProvider provider, StateSetter setStateMenu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: n.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: n.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 24, color: n.color),
            const SizedBox(width: 12),
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
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () {
                setStateMenu(() {
                  provider.removeNotification(n.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
