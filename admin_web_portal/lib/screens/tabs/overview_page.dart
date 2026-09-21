import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/work_order_provider.dart';
import '../../services/api_service.dart';

class OverviewPage extends StatefulWidget {
  final Function(int)? onNavigateToEmployees;
  final Function(int)? onNavigateToWorkOrders;

  const OverviewPage(
      {super.key, this.onNavigateToEmployees, this.onNavigateToWorkOrders});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int _activeCount = 0;
  int _leaveCount = 0;
  int _pendingApprovalsCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchEmployeeStats();
    _fetchApprovals();
  }

  Future<void> _fetchEmployeeStats() async {
    try {
      final response = await _apiService.get('/users/executives');
      final List<dynamic> data = response ?? [];
      if (mounted) {
        setState(() {
          _activeCount = data.where((e) => e != null && e['status'] == 'Active').length;
          _leaveCount = data.where((e) => e != null && e['status'] == 'On Leave').length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching employee stats: $e');
    }
  }

  Future<void> _fetchApprovals() async {
    try {
      final response = await _apiService.get('/approvals');
      final List<dynamic> data = response ?? [];
      if (mounted) {
        setState(() {
          _pendingApprovalsCount = data.where((a) => a != null && a['status'] == 'PENDING').length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching approvals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workOrderProvider = Provider.of<WorkOrderProvider>(context);
    final globalWorkOrders = workOrderProvider.workOrders;

    final int tasksPending =
        globalWorkOrders.where((w) => w.status.toLowerCase() == 'pending').length;
    final int tasksCompleted =
        globalWorkOrders.where((w) => w.status.toLowerCase() == 'completed').length;
    final int complaintsPending =
        globalWorkOrders.where((w) => w.status.toLowerCase() == 'executive_pending').length;
    final int pendingApprovals = _pendingApprovalsCount;

    final double completedPaymentsAmount = globalWorkOrders
        .where((w) => w.status.toLowerCase() == 'completed' && w.finalBill != null)
        .fold(0.0, (sum, w) {
          final billString = w.finalBill!.replaceAll(RegExp(r'[^0-9.]'), '');
          return sum + (double.tryParse(billString) ?? 0.0);
        });

    final double paymentPendingAmount = globalWorkOrders
        .where((w) => w.status.toLowerCase() == 'payment pending' && w.finalBill != null)
        .fold(0.0, (sum, w) {
          final billString = w.finalBill!.replaceAll(RegExp(r'[^0-9.]'), '');
          return sum + (double.tryParse(billString) ?? 0.0);
        });

    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time operational metrics across all services.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 60, height: 60),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Tasks Pending', '$tasksPending',
                        Icons.hourglass_empty, Colors.amber,
                        onTap: () => widget.onNavigateToWorkOrders?.call(0), index: 0),
                    _buildStatCard('Tasks Completed', '$tasksCompleted',
                        Icons.check_circle, Colors.green,
                        onTap: () => widget.onNavigateToWorkOrders?.call(3), index: 1),
                    _buildStatCard('Pending Approvals', '$pendingApprovals',
                        Icons.pending_actions, Colors.red,
                        onTap: () => widget.onNavigateToWorkOrders?.call(5), index: 2),
                    _buildStatCard(
                        'Pending Complaints',
                        '$complaintsPending',
                        Icons.report_problem_outlined,
                        Colors.deepOrange,
                        onTap: () => widget.onNavigateToWorkOrders?.call(2),
                        index: 3),
                    _buildStatCard('Active Executives', '$_activeCount',
                        Icons.engineering, Colors.blue,
                        onTap: () => widget.onNavigateToEmployees?.call(1), index: 4),
                    _buildStatCard('Executives on Leave', '$_leaveCount',
                        Icons.beach_access, Colors.purple,
                        onTap: () => widget.onNavigateToEmployees?.call(1), index: 5),
                    _buildStatCard(
                        'Payment Pending',
                        currencyFormat.format(paymentPendingAmount),
                        Icons.pending,
                        Colors.orange,
                        onTap: () => widget.onNavigateToWorkOrders?.call(4),
                        index: 6),
                    _buildStatCard(
                        'Payments Total (Today)',
                        currencyFormat.format(completedPaymentsAmount),
                        Icons.currency_rupee,
                        Colors.teal,
                        index: 7),
                  ],
                );
              }
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildStatCard(
    String title, String value, IconData icon, MaterialColor color,
    {VoidCallback? onTap, int index = 0}) {
  return _StatCard(
    title: title,
    value: value,
    icon: icon,
    color: color,
    onTap: onTap,
    index: index,
  );
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback? onTap;
  final int index;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.index = 0,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(24),
            transform: Matrix4.diagonal3Values(
                _isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0, 1.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _isHovered ? 0.3 : 0.1),
                  blurRadius: _isHovered ? 30 : 20,
                  offset: Offset(0, _isHovered ? 15 : 10),
                )
              ],
              border: Border.all(
                  color: widget.color.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon,
                          color: widget.color.shade700, size: 24),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: widget.color.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
