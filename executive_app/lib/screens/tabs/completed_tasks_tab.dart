import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/api_data_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../services/api_service.dart';

class CompletedTasksTab extends StatefulWidget {
  const CompletedTasksTab({super.key});

  @override
  State<CompletedTasksTab> createState() => _CompletedTasksTabState();
}

class _CompletedTasksTabState extends State<CompletedTasksTab> {
  List<String> _clearedTaskIds = [];

  @override
  void initState() {
    super.initState();
    _loadClearedTasks();
  }

  Future<void> _loadClearedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final clearedStr = prefs.getString('cleared_completed_tasks');
    if (clearedStr != null) {
      setState(() {
        _clearedTaskIds = List<String>.from(jsonDecode(clearedStr));
      });
    }
  }

  Future<void> _clearTasks(List<dynamic> tasks) async {
    try {
      await ApiService().delete('/bookings/completed');
      if (mounted) {
        Provider.of<ApiDataProvider>(context, listen: false).fetchExecutiveTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completed tasks deleted from server')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _generatePdf(List<dynamic> tasks) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            text: 'Completed Complaints Audit Report',
          ),
          pw.SizedBox(height: 20),
          ...tasks.map((task) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Service: ${task['serviceName'] ?? task['type'] ?? 'AC Service'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text('Order ID: ${task['orderId'] ?? task['id'] ?? 'Unknown'}'),
                  pw.Text('Customer: ${task['customerName'] ?? 'Unknown'}'),
                  pw.Text('Mobile: ${task['customerMobile'] ?? 'N/A'}'),
                  pw.Text('Address: ${task['customerAddress'] ?? 'N/A'}'),
                  if (task['planName'] != null) pw.Text('Plan Applied: ${task['planName']}'),
                  if (task['couponCode'] != null) pw.Text('Coupon: ${task['couponCode']}'),
                  if (task['finalBill'] != null) pw.Text('Final Bill: Rs. ${task['finalBill']}'),
                  if (task['rewardPoints'] != null) pw.Text('Reward Points Earned: ${task['rewardPoints']}'),
                  if (task['rating'] != null) pw.Text('Customer Rating: ${task['rating']} / 5'),
                  pw.SizedBox(height: 5),
                  pw.Text('Status: Completed', style: const pw.TextStyle(color: PdfColors.green)),
                ],
              ),
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Completed_Complaints_Audit.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        actions: [
          Consumer<ApiDataProvider>(
            builder: (context, dataProvider, child) {
              final tasks = dataProvider.bookings.where((b) {
                final st = (b['status'] as String?)?.toLowerCase();
                final isCompleted = st == 'completed' || st == 'complaint closed thank you for choosing protech cooling solutions';
                final isNotCleared = !_clearedTaskIds.contains(b['id'].toString());
                return isCompleted && isNotCleared;
              }).toList();

              return Row(
                children: [
                  if (tasks.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      tooltip: 'Save as PDF',
                      onPressed: () => _generatePdf(tasks),
                    ),
                  if (tasks.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Clear All',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Completed List?'),
                            content: const Text('This will hide all currently displayed completed tasks from your view.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _clearTasks(tasks);
                        }
                      },
                    ),
                ],
              );
            },
          ),
          const NotificationBell(),
        ],
      ),
      body: Consumer<ApiDataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = dataProvider.bookings.where((b) {
            final st = (b['status'] as String?)?.toLowerCase();
            final isCompleted = st == 'completed' || st == 'complaint closed thank you for choosing protech cooling solutions';
            final isNotCleared = !_clearedTaskIds.contains(b['id'].toString());
            return isCompleted && isNotCleared;
          }).toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No completed tasks.'),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
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
                                const SizedBox(height: 8),
                                if (task['planName'] != null)
                                  Text('Plan Applied: ${task['planName']}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                                if (task['couponCode'] != null)
                                  Text('Coupon: ${task['couponCode']}', style: const TextStyle(color: Colors.green)),
                                if (task['finalBill'] != null)
                                  Text('Final Bill: ₹${task['finalBill']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (task['rewardPoints'] != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text('+${task['rewardPoints']} Reward Points', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                if (task['rating'] != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text('${task['rating']} / 5 Customer Rating', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.check_circle, color: Colors.green, size: 32),
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
