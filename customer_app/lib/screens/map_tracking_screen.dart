import 'package:flutter/material.dart';
import 'dart:async';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Fetch latest status when this screen is initialized
    AppState().fetchOrdersFromServer();

    // Auto refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      AppState().fetchOrdersFromServer();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await AppState().fetchOrdersFromServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tracking Orders'),
        automaticallyImplyLeading: false,
        actions: [
          ValueListenableBuilder<List<String>>(
              valueListenable: AppState().clearedNotificationsNotifier,
              builder: (context, clearedIds, _) {
                return ValueListenableBuilder<List<Order>>(
                  valueListenable: AppState().ordersNotifier,
                  builder: (context, orders, child) {
                    final visibleOrders = orders
                        .where((o) => !clearedIds.contains(o.orderId))
                        .toList();
                    return IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined),
                          if (visibleOrders.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  '${visibleOrders.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => _showNotificationsSheet(context),
                    );
                  },
                );
              }),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<List<Order>>(
        valueListenable: AppState().ordersNotifier,
        builder: (context, orders, child) {
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: const CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No complaints booked yet.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order =
                    orders[orders.length - 1 - index]; // Show latest first
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildTrackingCard(
                    orderId: order.orderId,
                    service: order.serviceName,
                    executiveName: order.executiveName,
                    executivePhone: order.executivePhone,
                    status: order.status,
                    isPending:
                        order.status == 'Awaiting for Approval from Admin' ||
                            order.status == 'Pending',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showDialog(
      context: context,
      barrierColor:
          Colors.transparent, // Don't darken the background like a modal
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 40, right: 16),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                width: 300,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ValueListenableBuilder<List<String>>(
                    valueListenable: AppState().clearedNotificationsNotifier,
                    builder: (context, clearedIds, _) {
                      return ValueListenableBuilder<List<Order>>(
                          valueListenable: AppState().ordersNotifier,
                          builder: (context, orders, _) {
                            final visibleOrders = orders
                                .where((o) => !clearedIds.contains(o.orderId))
                                .toList();

                            if (visibleOrders.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No new notifications',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Notifications',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () {
                                          AppState().clearAllNotifications(
                                              visibleOrders
                                                  .map((o) => o.orderId)
                                                  .toList());
                                        },
                                        child: const Text('Clear all',
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Flexible(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: visibleOrders.length,
                                    itemBuilder: (context, index) {
                                      final order = visibleOrders[
                                          visibleOrders.length - 1 - index];
                                      return Dismissible(
                                        key: Key(order.orderId),
                                        direction: DismissDirection.endToStart,
                                        onDismissed: (direction) {
                                          AppState()
                                              .clearNotification(order.orderId);
                                        },
                                        background: Container(
                                          color: Colors.red,
                                          alignment: Alignment.centerRight,
                                          padding:
                                              const EdgeInsets.only(right: 16),
                                          child: const Icon(Icons.delete,
                                              color: Colors.white, size: 20),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 4),
                                          title: Text('Order ${order.orderId}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13)),
                                          subtitle: Text(
                                              'Status: ${order.status}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          });
                    }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackingCard({
    required String orderId,
    required String service,
    required String executiveName,
    required String executivePhone,
    required String status,
    bool isPending = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onLongPress: () {
                  // Hidden feature to mock admin advancing status
                  AppState().advanceOrderStatus(orderId);
                },
                child: Text(
                  'Order ID: $orderId',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isPending ? AppColors.primarySoft : AppColors.primaryMid,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPending ? 'Pending' : 'Active',
                  style: TextStyle(
                    color: isPending ? AppColors.primaryDark : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            service,
            style: const TextStyle(
                fontSize: 18,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Executive: $executiveName',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Contact: $executivePhone',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          _buildLifecycleTimeline(status),
        ],
      ),
    );
  }

  Widget _buildLifecycleTimeline(String currentStatus) {
    final isDeleted =
        currentStatus == 'Your complaint deleted by Protech Cooling solutions';
    final stages = <String>[
      'Awaiting for Approval from Admin',
      'Assign to Executive',
      'On the Way',
    ];

    if (currentStatus == 'In Progress' || currentStatus == 'Closed') {
      stages.add('In Progress');
    } else if (currentStatus == 'Pending') {
      stages.add('In Progress');
      stages.add('Pending');
    }

    stages.add(isDeleted
        ? 'Your complaint deleted by Protech Cooling solutions'
        : 'Closed');

    int currentIndex = stages.indexOf(currentStatus);
    if (currentIndex == -1) {
      if (currentStatus == 'Closed') {
        currentIndex = stages.length - 1;
      } else {
        currentIndex = 0;
      }
    }

    return Column(
      children: List.generate(stages.length, (index) {
        bool isCompleted = index <= currentIndex;
        bool isLast = index == stages.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.primaryMid
                        : AppColors.background,
                    border: Border.all(
                      color:
                          isCompleted ? AppColors.primaryMid : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color:
                        isCompleted ? AppColors.primaryMid : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  _formatStageName(stages[index]),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isCompleted ? FontWeight.bold : FontWeight.normal,
                    color:
                        isCompleted ? AppColors.textDark : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatStageName(String stage) {
    if (stage == 'Awaiting for Approval from Admin') return 'Awaiting Approval';
    return stage;
  }
}
