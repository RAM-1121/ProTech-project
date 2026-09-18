import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_data_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiDataProvider>().fetchAdminBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Consumer<ApiDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          final bookings = provider.bookings;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${b['type']} - ${b['status']}'),
                  subtitle: Text('Customer ID: ${b['customerId']} \nDate: ${b['date']}'),
                  trailing: b['status'] == 'Pending' 
                    ? ElevatedButton(
                        onPressed: () {
                          // Assign to exec 1 (mocking executive picker)
                          context.read<ApiDataProvider>().assignExecutive(b['id'], 1);
                        },
                        child: const Text('Assign to Exec 1'),
                      )
                    : Text('Exec: ${b['assignedExecutiveId']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
