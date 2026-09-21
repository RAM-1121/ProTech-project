import 'package:flutter/material.dart';
import 'dart:async';
import '../models/app_state.dart';
import '../theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  Timer? _refreshTimer;

  bool _showItems = false;

  @override
  void initState() {
    super.initState();
    // Fetch latest status when this screen is initialized
    AppState().fetchOrdersFromServer();

    // Auto refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      AppState().fetchOrdersFromServer();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showItems = true);
      }
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Tracking Orders'),
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.primaryMid,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryMid.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    tabs: const [
                      Tab(text: 'Active'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          final activeOrders = orders.where((o) => o.status != 'Complaint Closed Thank You For choosing Protech Cooling Solutions' && o.status != 'Your complaint deleted by Protech Cooling solutions' && o.status != 'Deleted By ADMIN').toList();
          final completedOrders = orders.where((o) => o.status == 'Complaint Closed Thank You For choosing Protech Cooling Solutions' || o.status == 'Your complaint deleted by Protech Cooling solutions' || o.status == 'Deleted By ADMIN').toList();

          return TabBarView(
            children: [
              _buildOrdersList(activeOrders, isActive: true),
              _buildOrdersList(completedOrders, isActive: false),
            ],
          );
        },
      ),
    ));
  }

  Widget _buildOrdersList(List<Order> ordersToDisplay, {required bool isActive}) {
    if (ordersToDisplay.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Text(
                  isActive ? 'No active complaints.' : 'No completed complaints.',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
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
        itemCount: ordersToDisplay.length,
        itemBuilder: (context, index) {
          final order = ordersToDisplay[ordersToDisplay.length - 1 - index]; // Show latest first
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _showItems ? 1.0 : 0.0),
            duration: Duration(milliseconds: 400 + (index * 150)),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - val)),
                child: Opacity(
                  opacity: val,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _ExpandableTrackingCard(
                order: order,
                isActive: isActive,
                detailedCard: _buildDetailedTrackingCard(
                  orderId: order.orderId,
                  service: order.serviceName,
                  executiveName: order.executiveName,
                  executivePhone: order.executivePhone,
                  status: order.status,
                  isPending: order.status == 'Your Complaint is Pending' || order.status == 'Pending' || order.status == 'Your Complaint is Pending',
                ),
              ),
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

  Widget _buildDetailedTrackingCard({
    required String orderId,
    required String service,
    required String executiveName,
    required String executivePhone,
    required String status,
    bool isPending = false,
  }) {
    final isClosed = status == 'Complaint Closed Thank You For choosing Protech Cooling Solutions';

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
          if (isClosed) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            _buildRatingWidget(orderId),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingWidget(String orderId) {
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setState) {
        // Read from AppState order
        final order = AppState().ordersNotifier.value.firstWhere(
            (o) => o.orderId == orderId,
            orElse: () => Order(orderId: orderId, serviceName: '')
        );

        int currentRating = order.rating ?? AppState().getOrderRating(orderId) ?? 0;
        bool isSubmitted = order.rating != null;

        Future<void> submitRating() async {
          if (currentRating == 0) return;
          setState(() { isSubmitting = true; });

          try {
            final response = await http.patch(
              Uri.parse('${AppState().apiBaseUrl}/api/bookings/$orderId/rating'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'rating': currentRating}),
            );
            
            if (!context.mounted) return;

            if (response.statusCode == 200 || response.statusCode == 201) {
              order.rating = currentRating;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rating submitted successfully!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to submit rating. Please try again.')),
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          } finally {
            if (context.mounted) {
              setState(() { isSubmitting = false; });
            }
          }
        }

        return Column(
          children: [
            const Text(
              'How was your service?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < currentRating ? Icons.star : Icons.star_border,
                    color: index < currentRating ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                  onPressed: isSubmitted || isSubmitting ? null : () {
                    AppState().setOrderRating(orderId, index + 1);
                    setState(() {});
                  },
                );
              }),
            ),
            if (!isSubmitted && currentRating > 0) ...[
              const SizedBox(height: 16),
              isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMid,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ]
          ],
        );
      },
    );
  }

  Widget _buildLifecycleTimeline(String currentStatus) {
    final isDeleted =
        currentStatus.toLowerCase().contains('deleted');
    final stages = <String>[
      'Your Complaint is Pending',
      'Assign to Executive Person',
      'Executive Person Is On The Way',
      'Payment Pending',
      'Complaint Closed Thank You For choosing Protech Cooling Solutions'
    ];

    int currentIndex = stages.indexOf(currentStatus);
    if (currentIndex == -1) {
      if (isDeleted) {
        // If it's deleted, replace the final stage with the deleted message
        stages[4] = 'Request is deleted';
        currentIndex = 4;
      } else {
        currentIndex = 0;
      }
    } else if (isDeleted) {
      stages[4] = 'Request is deleted';
      currentIndex = 4;
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
    return stage;
  }

}

class _ExpandableTrackingCard extends StatefulWidget {
  final Order order;
  final bool isActive;
  final Widget detailedCard;

  const _ExpandableTrackingCard({
    required this.order,
    required this.isActive,
    required this.detailedCard,
  });

  @override
  State<_ExpandableTrackingCard> createState() => _ExpandableTrackingCardState();
}

class _ExpandableTrackingCardState extends State<_ExpandableTrackingCard> {
  bool _isExpanded = false;

  Widget _buildCapsuleButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryMid,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMid.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = !widget.isActive;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.08),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 6),
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
              Text(
                'Order ID: ${widget.order.orderId}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? (widget.order.status.toLowerCase().contains('deleted') ? Colors.red.shade100 : Colors.green.shade100) : (widget.order.status == 'Payment Pending' ? Colors.orange.shade100 : (widget.order.status == 'Pending' || widget.order.status == 'Your Complaint is Pending' ? AppColors.primarySoft : AppColors.primaryMid)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCompleted ? (widget.order.status.toLowerCase().contains('deleted') ? 'Deleted' : 'Completed') : (widget.order.status == 'Payment Pending' ? 'Payment Pending' : (widget.order.status == 'Pending' || widget.order.status == 'Your Complaint is Pending' ? 'Pending' : 'Active')),
                  style: TextStyle(
                    color: isCompleted ? (widget.order.status.toLowerCase().contains('deleted') ? Colors.red.shade800 : Colors.green.shade800) : (widget.order.status == 'Payment Pending' ? Colors.orange.shade800 : (widget.order.status == 'Pending' || widget.order.status == 'Your Complaint is Pending' ? AppColors.primaryDark : Colors.white)),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            widget.order.serviceName,
            style: const TextStyle(
                fontSize: 18,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (isCompleted) ...[
             Text(
               widget.order.status.toLowerCase().contains('deleted') ? 'Request is deleted' : 'Complaint closed by Protech Cooling Solutions',
               style: const TextStyle(fontSize: 14, color: Colors.grey),
             ),
             const SizedBox(height: 16),
          ],
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: widget.detailedCard,
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          _buildCapsuleButton(_isExpanded ? 'Hide Details' : 'View Details', () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }),

        ],
      ),
    );
  }
}

