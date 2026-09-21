import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:provider/provider.dart';
import '../../providers/api_data_provider.dart';

import 'package:flutter/material.dart';
import 'tabs/job_works_tab.dart';
import 'tabs/task_status_tab.dart';
import 'tabs/pending_tasks_tab.dart';
import 'tabs/completed_tasks_tab.dart';
import 'tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnect((_) {
      debugPrint('Executive App Socket connected');
    });
    socket.onDisconnect((_) {
      debugPrint('Executive App Socket disconnected');
    });
    socket.on('update_received', (payload) {
      debugPrint('Executive App received update via socket!');
      if (mounted) {
        if (payload != null && payload is Map) {
          if (payload['type'] == 'EXECUTIVE_UPDATE' && payload['data'] != null) {
            context.read<ApiDataProvider>().updateProfileLocally(Map<String, dynamic>.from(payload['data']));
          } else if (payload['type'] == 'RATING_UPDATE' && payload['data'] != null) {
             final eventData = payload['data'];
             final msg = 'Order ID ${eventData['orderId'] ?? eventData['id']} and ${eventData['rating'] ?? 0}/5';
             context.read<ApiDataProvider>().addNotification(
                NotificationItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Rating Update',
                  subtitle: msg,
                  color: Colors.amber,
                )
             );
          } else if (payload['type'] == 'NEW_WORK_ORDER' && payload['data'] != null) {
             final eventData = payload['data'];
             final msg = 'New work order received: ${eventData['serviceName'] ?? eventData['type'] ?? 'Task'}';
             context.read<ApiDataProvider>().addNotification(
                NotificationItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'New Work Order',
                  subtitle: msg,
                  color: Colors.blueAccent,
                )
             );
          } else if (payload['type'] == 'STATUS_UPDATE' && payload['data'] != null) {
             final eventData = payload['data'];
             final msg = 'Order ID ${eventData['orderId'] ?? eventData['id']} is now ${eventData['status']}';
             context.read<ApiDataProvider>().addNotification(
                NotificationItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Task Status Updated',
                  subtitle: msg,
                  color: Colors.green,
                )
             );
          } else if (payload['type'] == 'REWARD_APPROVED' && payload['data'] != null) {
             final eventData = payload['data'];
             final myEmployeeId = context.read<ApiDataProvider>().myProfile?['employeeId'];
             if (myEmployeeId != null && myEmployeeId == eventData['employeeId']) {
               final msg = '${eventData['amount']} points redeemed successfully!';
               context.read<ApiDataProvider>().addNotification(
                  NotificationItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: 'Reward Approved',
                    subtitle: msg,
                    color: Colors.amber,
                  )
               );
             }
          } else if (payload['type'] == 'REWARD_REJECTED' && payload['data'] != null) {
             final eventData = payload['data'];
             final myEmployeeId = context.read<ApiDataProvider>().myProfile?['employeeId'];
             if (myEmployeeId != null && myEmployeeId == eventData['employeeId']) {
               final msg = 'Redemption of ${eventData['amount']} points was rejected.';
               context.read<ApiDataProvider>().addNotification(
                  NotificationItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: 'Reward Rejected',
                    subtitle: msg,
                    color: Colors.redAccent,
                  )
               );
             }
          } else if (payload['type'] == 'DELETE_WORK_ORDER' && payload['data'] != null) {
             final eventData = payload['data'];
             final msg = 'Order ID ${eventData['orderId'] ?? eventData['id']} was removed.';
             context.read<ApiDataProvider>().addNotification(
                NotificationItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Task Removed',
                  subtitle: msg,
                  color: Colors.redAccent,
                )
             );
          }
        }
        context.read<ApiDataProvider>().fetchExecutiveTasks(silent: true);
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  final List<Widget> _screens = [
    const JobWorksTab(),
    const TaskStatusTab(),
    const PendingTasksTab(),
    const CompletedTasksTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomAnimatedBottomBar(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class CustomAnimatedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const CustomAnimatedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.work_outline_rounded, Icons.work_rounded, 'Works'),
              _buildNavItem(1, Icons.donut_large_outlined, Icons.donut_large_rounded, 'Status'),
              _buildNavItem(2, Icons.hourglass_empty_rounded, Icons.hourglass_bottom_rounded, 'Pending'),
              _buildNavItem(3, Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Done'),
              _buildNavItem(4, Icons.account_circle_outlined, Icons.account_circle_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.blueAccent : Colors.grey[600],
              size: 24,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
