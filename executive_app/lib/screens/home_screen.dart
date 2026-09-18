import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_data_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: const Text('Assigned Tasks'),
      ),
      body: Consumer<ApiDataProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = provider.bookings; // Example exec ID
          if (tasks.isEmpty) {
            return const Center(child: Text('No assigned tasks.'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.work, color: Colors.blue),
                  title: Text('${task.type} Service'),
                  subtitle: Text('Status: ${task.status}\nAddress: ${task.address}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Action to start job
                    },
                    child: const Text('View'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
