import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/api_data_provider.dart';
import '../route_map_screen.dart';
import '../../widgets/notification_bell.dart';
import 'package:latlong2/latlong.dart';

class JobWorksTab extends StatefulWidget {
  const JobWorksTab({super.key});

  @override
  State<JobWorksTab> createState() => _JobWorksTabState();
}

class _JobWorksTabState extends State<JobWorksTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiDataProvider>().fetchExecutiveTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Works'),
        actions: const [NotificationBell()],
      ),
      body: Consumer<ApiDataProvider>(
        builder: (context, dataProvider, child) {
          if (dataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = dataProvider.bookings.where((b) => (b['status'] as String?)?.toLowerCase() == 'assigned').toList();

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No assigned complaints.'),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
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
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        ),
                        const Divider(height: 1),
                          OverflowBar(
                            alignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.directions, color: Colors.blueAccent),
                                label: const Text('Directions', style: TextStyle(color: Colors.blueAccent)),
                                onPressed: () {
                                  final coords = task['customerCoordinates']?.toString().split(',');
                                  if (coords != null && coords.length == 2) {
                                    final lat = double.tryParse(coords[0]) ?? 0.0;
                                    final lng = double.tryParse(coords[1]) ?? 0.0;
                                    
                                    final myProfile = context.read<ApiDataProvider>().myProfile;
                                    double startLat = 17.385044;
                                    double startLng = 78.486671;
                                    if (myProfile != null && myProfile['currentLocation'] != null) {
                                      final loc = myProfile['currentLocation'];
                                      if (loc['coordinates'] != null && loc['coordinates'] is List) {
                                        startLng = (loc['coordinates'][0] as num).toDouble();
                                        startLat = (loc['coordinates'][1] as num).toDouble();
                                      }
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RouteMapScreen(
                                          startLocation: LatLng(startLat, startLng),
                                          endLocation: LatLng(lat, lng),
                                          customerName: task['customerName'] ?? 'Customer',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer coordinates not available')));
                                  }
                                },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () async {
                                  final success = await context.read<ApiDataProvider>().updateTaskStatus(
                                    bookingId: task['id'], 
                                    status: 'in_progress',
                                  );
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Accepted')));
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to accept task')));
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Accept'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ],
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
