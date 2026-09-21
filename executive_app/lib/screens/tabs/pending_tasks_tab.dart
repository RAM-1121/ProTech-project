import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/api_data_provider.dart';
import '../../widgets/notification_bell.dart';
import 'payment_bottom_sheet.dart';

class PendingTasksTab extends StatelessWidget {
  const PendingTasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Tasks'),
        actions: const [NotificationBell()],
      ),
      body: Consumer<ApiDataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = dataProvider.bookings.where((b) {
            final status = (b['status'] as String?)?.toLowerCase();
            return status == 'pending' || status == 'on_hold' || status == 'executive_pending' || status == 'payment pending';
          }).toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No pending tasks.'),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isPaymentPending = (task['status'] as String?)?.toLowerCase() == 'payment pending';
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(task['serviceName'] ?? task['type'] ?? 'AC Service', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Order ID: ${task['orderId'] ?? task['id'] ?? 'Unknown'}'),
                                Text('Customer: ${task['customerName'] ?? 'Unknown'}'),
                                Text('Mobile: ${task['customerMobile'] ?? 'N/A'}'),
                                Text('Address: ${task['customerAddress'] ?? 'N/A'}'),
                                if (task['customerCoordinates'] != null && task['customerCoordinates'].toString().isNotEmpty)
                                  Text('Coordinates: ${task['customerCoordinates']}'),
                                if (isPaymentPending)
                                  const Text('Status: Payment Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                if (task['pendingReason'] != null || task['reason'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Reason: ${task['pendingReason'] ?? task['reason']}', style: const TextStyle(color: Colors.redAccent)),
                                ]
                              ],
                            ),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () async {
                                if (isPaymentPending) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) => PaymentBottomSheet(task: task),
                                  );
                                } else {
                                  final success = await context.read<ApiDataProvider>().updateTaskStatus(
                                    bookingId: task['id'], 
                                    status: 'in_progress',
                                  );
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Resumed')));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resume task')));
                                    }
                                  }
                                }
                              },
                              child: Text(isPaymentPending ? 'Collect' : 'Resume'),
                            ),
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
