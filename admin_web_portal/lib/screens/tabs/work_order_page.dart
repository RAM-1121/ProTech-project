import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/work_order_provider.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/api_service.dart';
import 'employee_page.dart';

class Payment {
  final String id;
  final double amount;
  String status;
  final DateTime date;
  Payment(
      {required this.id,
      required this.amount,
      required this.status,
      required this.date});
}

class Approval {
  final String id;
  final String description;
  String status;
  Approval({required this.id, required this.description, required this.status});
}

final List<Payment> globalPayments = [
  Payment(id: 'P-1', amount: 1500, status: 'Pending', date: DateTime.now()),
  Payment(id: 'P-2', amount: 600, status: 'Pending', date: DateTime.now()),
  Payment(id: 'P-3', amount: 14500, status: 'Completed', date: DateTime.now()),
];

final List<Approval> globalApprovals = [
  for (int i = 0; i < 5; i++)
    Approval(id: 'A-$i', description: 'Pending Request', status: 'Pending'),
];

class WorkOrderPage extends StatefulWidget {
  final int initialIndex;
  const WorkOrderPage({super.key, this.initialIndex = 0});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  @override
  void initState() {
    super.initState();
    // We already fetch in the provider's constructor, so we just let it load.
  }

  Future<void> _generatePdf(List<WorkOrder> completedTasks) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            text: 'Completed Complaints Audit Report (Admin)',
          ),
          pw.SizedBox(height: 20),
          ...completedTasks.map((task) {
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
                  pw.Text('Service: ${task.title}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 5),
                  pw.Text('Order ID: ${task.id}'),
                  pw.Text('Customer: ${task.customerName ?? 'Unknown'}'),
                  pw.Text('Mobile: ${task.customerMobile ?? 'N/A'}'),
                  pw.Text('Address: ${task.customerAddress ?? 'N/A'}'),
                  if (task.planName != null) pw.Text('Plan Applied: ${task.planName}'),
                  if (task.couponCode != null) pw.Text('Coupon: ${task.couponCode}'),
                  if (task.finalBill != null) pw.Text('Final Bill: Rs. ${task.finalBill}'),
                  if (task.rewardPoints != null) pw.Text('Reward Points Earned: ${task.rewardPoints}'),
                  if (task.rating != null) pw.Text('Customer Rating: ${task.rating} / 5'),
                  pw.SizedBox(height: 5),
                  pw.Text('Status: Completed', style: const pw.TextStyle(color: PdfColors.green)),
                ],
              ),
            );
          }),
        ],
      ),
    );

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'Admin_Completed_Complaints_Audit.pdf';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _clearCompletedBookings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Completed Tasks?'),
        content: const Text('This will permanently delete all completed tasks from the database to save space. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final provider = Provider.of<WorkOrderProvider>(context, listen: false);
      try {
        await ApiService().delete('/bookings/completed');
        provider.fetchWorkOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All completed tasks have been deleted.')),
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
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: widget.initialIndex,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 24, left: 32, right: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Work Orders',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Consumer<WorkOrderProvider>(
                      builder: (context, provider, child) {
                        final completedOrders = provider.workOrders.where((w) => w.status.toLowerCase() == 'completed' || w.status.toLowerCase() == 'payment pending' || w.status.toLowerCase() == 'complaint closed thank you for choosing protech cooling solutions').toList();
                        return Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _generatePdf(completedOrders),
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('Save as PDF'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                              onPressed: _clearCompletedBookings,
                              icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.white),
                              label: const Text('Delete Completed', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.blueGrey.shade600,
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashFactory: NoSplash.splashFactory,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 0))
                        ]),
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(
                          height: 44,
                          child: Center(
                              child: Text('Work / Complaints',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      Tab(
                          height: 44,
                          child: Center(
                              child: Text('Assigned Tasks',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      Tab(
                          height: 44,
                          child: Center(
                              child: Text('Complaints Pending',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      Tab(
                          height: 44,
                          child: Center(
                              child: Text('Complaints Completed',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      Tab(
                          height: 44,
                          child: Center(
                              child: Text('Payments Pending',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                      Tab(
                          height: 44,
                          child: Center(
                              child: Text('Employee Approvals',
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<WorkOrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text('Error: ${provider.error}'));
                }
                
                final orders = provider.workOrders;

                return TabBarView(
                  children: [
                    // 1. Work / Complaints (Pending)
                    _WorkOrderListTab(
                        orders: orders
                            .where((w) => w.status.toLowerCase() == 'pending')
                            .toList()),
                    // 2. Assigned Tasks
                    _WorkOrderListTab(
                        sortByEmployee: true,
                        orders: orders
                            .where((w) => w.status.toLowerCase() == 'assigned' || w.status.toLowerCase() == 'rejected')
                            .toList()),
                    // 3. Complaints Pending (executive_pending)
                    _WorkOrderListTab(
                        orders: orders
                            .where((w) => w.status.toLowerCase() == 'executive_pending')
                            .toList()),
                    // 4. Complaints Completed
                    _WorkOrderListTab(
                        orders: orders
                            .where((w) => w.status.toLowerCase() == 'completed')
                            .toList()),
                    // 5. Payments Pending
                    _WorkOrderListTab(
                        orders: orders
                            .where((w) => w.status.toLowerCase() == 'payment pending')
                            .toList()),
                    // 6. Employee Approvals
                    _ApprovalListTab(approvals: globalApprovals),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String text;
  const _PlaceholderTab(this.text);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        color: const Color(0xFFF4F7FC),
        padding: const EdgeInsets.all(32),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ]),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 80, color: Colors.blueGrey.shade200),
                const SizedBox(height: 24),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkOrderListTab extends StatelessWidget {
  final List<WorkOrder> orders;
  final bool sortByEmployee;
  const _WorkOrderListTab({required this.orders, this.sortByEmployee = false});

  void _showAssignDialog(BuildContext context, WorkOrder order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign ${order.title}'),
          content: SizedBox(
            width: 400,
            child: FutureBuilder(
              future: ApiService().get('/users/executives'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final List<dynamic> data = snapshot.data as List<dynamic>;
                final activeEmployees = data
                    .where((e) => e['status'] == 'Active')
                    .map((e) => Employee.fromJson(e))
                    .toList();

                if (activeEmployees.isEmpty) {
                  return const Text('No active employees available.');
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeEmployees.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final emp = activeEmployees[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: emp.color.withValues(alpha: 0.1),
                        child: Icon(Icons.person, color: emp.color),
                      ),
                      title: Text(emp.name),
                      subtitle: Text(emp.experience),
                      trailing: ElevatedButton(
                        onPressed: () {
                          context.read<WorkOrderProvider>().updateWorkOrderStatus(order.id, 'Assigned', {
                            'id': emp.id,
                            'name': emp.name,
                            'mobile': emp.phone,
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${order.id} assigned to ${emp.name}')),
                          );
                        },
                        child: const Text('Assign'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildTrailingAction(BuildContext context, WorkOrder order) {
    final status = order.status.toLowerCase();
    
    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: const Text('Actions'),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
            items: const [
              DropdownMenuItem(
                value: 'assign',
                child: Text('Approved and Assigned to Executive Person'),
              ),
              DropdownMenuItem(
                value: 'reject',
                child: Text('Rejected'),
              ),
            ],
            onChanged: (value) {
              if (value == 'assign') {
                _showAssignDialog(context, order);
              } else if (value == 'reject') {
                context.read<WorkOrderProvider>().updateWorkOrderStatus(order.id, 'Rejected');
              }
            },
          ),
        ),
      );
    } else if (status == 'assigned') {
      return ElevatedButton(
        onPressed: () => _showAssignDialog(context, order),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: const Text('Change Executive'),
      );
    } else if (status == 'rejected') {
      return ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text('Are you sure you want to delete this work order? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    context.read<WorkOrderProvider>().deleteWorkOrder(order.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: const Text('Delete'),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _PlaceholderTab('No work orders found in this category.');
    }
    
    if (sortByEmployee) {
      final grouped = <String, List<WorkOrder>>{};
      for (final o in orders) {
        final empName = o.assignedEmployeeName?.isNotEmpty == true ? o.assignedEmployeeName! : 'Unassigned';
        grouped.putIfAbsent(empName, () => []).add(o);
      }
      
      final sortedKeys = grouped.keys.toList()..sort();
      
      return Container(
        color: const Color(0xFFF4F7FC),
        padding: const EdgeInsets.all(24),
        child: ListView.builder(
          itemCount: sortedKeys.length,
          itemBuilder: (context, index) {
            final empName = sortedKeys[index];
            final empOrders = grouped[empName]!;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 16,
                          child: Icon(Icons.person, size: 20, color: Colors.blue.shade800),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          empName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200)
                          ),
                          child: Text(
                            '${empOrders.length} Task${empOrders.length > 1 ? 's' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                  ...empOrders.asMap().entries.map((entry) {
                    final serial = entry.key + 1;
                    final order = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCard(
                        icon: Icons.build_circle,
                        iconColor: Colors.blue.shade600,
                        title: '$serial. ${order.title}',
                        subtitle: order.id,
                        status: order.status,
                        details: _buildCustomerDetails(order),
                        trailing: _buildTrailingAction(context, order),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      );
    }
    
    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(24),
      child: ListView.separated(
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildCard(
            icon: Icons.build_circle,
            iconColor: Colors.blue.shade600,
            title: order.title,
            subtitle: order.id,
            status: order.status,
            details: _buildCustomerDetails(order),
            trailing: _buildTrailingAction(context, order),
          );
        },
      ),
    );
  }
}

class _ApprovalListTab extends StatefulWidget {
  final List<Approval> approvals; // Still accepted but we'll fetch from API
  const _ApprovalListTab({required this.approvals});

  @override
  State<_ApprovalListTab> createState() => _ApprovalListTabState();
}

class _ApprovalListTabState extends State<_ApprovalListTab> {
  final ApiService _api = ApiService();
  List<dynamic> _backendApprovals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/approvals');
      setState(() {
        _backendApprovals = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading approvals: $e')));
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _api.patch('/approvals/$id/status', {'status': newStatus});
      await _fetchApprovals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_backendApprovals.isEmpty) {
      return const _PlaceholderTab('No pending approvals.');
    }
    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(24),
      child: ListView.separated(
        itemCount: _backendApprovals.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final a = _backendApprovals[index];
          final type = a['type'] ?? 'UNKNOWN';
          final status = a['status'] ?? 'PENDING';
          final employeeId = a['employeeId'] ?? '';
          final employeeName = a['employeeName'] ?? 'Unknown';
          final details = a['details'] ?? {};
          
          String titleText = 'Unknown Request';
          String subtitleText = 'Employee: $employeeName | ID: $employeeId\nSubmitted: ${a['createdAt'] != null ? a['createdAt'].toString().substring(0, 10) : ''}';
          
          if (type == 'ATTENDANCE') {
            final dates = (details['dates'] as List<dynamic>? ?? []).join(', ');
            final markAs = details['markAs'];
            if (markAs == 'PRESENT' || markAs == 'Present') {
              titleText = 'Present Request for: $dates';
            } else if (markAs == 'LEAVE' || markAs == 'Leave') {
              titleText = 'Leave Request for: $dates';
            } else {
              titleText = 'Attendance Request ($markAs) for: $dates';
            }
          } else if (type == 'REWARD') {
            final amount = details['amount'];
            titleText = 'Reward Redemption: $amount points';
          }

          return _buildCard(
            icon: type == 'REWARD' ? Icons.card_giftcard : Icons.event_available,
            iconColor: type == 'REWARD' ? Colors.amber.shade600 : Colors.purple.shade600,
            title: titleText,
            subtitle: subtitleText,
            status: status,
            trailing: (status == 'PENDING')
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateStatus(a['id'], 'APPROVED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateStatus(a['id'], 'REJECTED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}

Widget _buildCustomerDetails(WorkOrder order) {
  final hasName = order.customerName != null && order.customerName!.isNotEmpty;
  final hasMobile = order.customerMobile != null && order.customerMobile!.isNotEmpty;
  final hasAddress = order.customerAddress != null && order.customerAddress!.isNotEmpty;
  final hasCoordinates = order.customerCoordinates != null && order.customerCoordinates!.isNotEmpty;
  final hasPendingReason = order.pendingReason != null && order.pendingReason!.isNotEmpty;

  if (!hasName && !hasMobile && !hasAddress && !hasCoordinates && !hasPendingReason) {
    return const SizedBox.shrink();
  }
  
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blueGrey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blueGrey.shade100)
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasName)
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Text(order.customerName!, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600)),
            ],
          ),
        if (hasName && (hasMobile || hasAddress || hasCoordinates)) const SizedBox(height: 6),
        if (hasMobile)
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Text(order.customerMobile!, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
            ],
          ),
        if (hasMobile && (hasAddress || hasCoordinates)) const SizedBox(height: 6),
        if (hasAddress)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(order.customerAddress!, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
              ),
            ],
          ),
        if (order.planName != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.assignment, size: 14, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Text('Plan: ${order.planName}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
        if (order.couponCode != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.local_offer, size: 14, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Text('Coupon: ${order.couponCode}', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
        if (order.finalBill != null && (order.status.toLowerCase() == 'completed' || order.status.toLowerCase() == 'payment pending')) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.payments, size: 14, color: order.status.toLowerCase() == 'completed' ? Colors.green.shade600 : Colors.orange.shade600),
              const SizedBox(width: 8),
              Text('Final Bill: ₹${order.finalBill}', style: TextStyle(fontSize: 12, color: order.status.toLowerCase() == 'completed' ? Colors.green.shade800 : Colors.orange.shade800, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
        if (order.rating != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              Text('${order.rating} / 5 Customer Rating', style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
        if (hasAddress && hasCoordinates) const SizedBox(height: 6),
        if (hasCoordinates)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.my_location, size: 14, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(order.customerCoordinates!, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700)),
              ),
            ],
          ),
        if (hasCoordinates && hasPendingReason) const SizedBox(height: 6),
        if (hasPendingReason)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.redAccent.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Reason: ${order.pendingReason!}', style: TextStyle(fontSize: 12, color: Colors.redAccent.shade700, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
      ],
    ),
  );
}

Widget _buildCard(
    {required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String status,
    Widget? details,
    Widget? trailing}) {
  Color statusColor;
  if (status == 'Completed' || status == 'Approved') {
    statusColor = Colors.green;
  } else if (status == 'Pending') {
    statusColor = Colors.amber;
  } else if (status == 'Paused' || status == 'Rejected') {
    statusColor = Colors.red;
  } else {
    statusColor = Colors.blue;
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ]),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      TextStyle(color: Colors.blueGrey.shade400, fontSize: 13)),
              if (details != null) ...[
                const SizedBox(height: 8),
                details,
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor.withAlpha(200),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 16),
        trailing ??
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.blueGrey.shade200),
      ],
    ),
  );
}
