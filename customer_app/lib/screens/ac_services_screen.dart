import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class ACServicesScreen extends StatelessWidget {
  const ACServicesScreen({super.key});

  void _bookService(BuildContext context, String serviceName) async {
    // Generate order and save to state
    final orderId = await AppState().addOrder('AC', serviceName);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Text('Booking Order ID $orderId\nYour complain Has Booked. Thank You For Booking Your Services With Protech Cooling Solutions'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close popup
              Navigator.pop(context); // Return to Booking Tab
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Go back to Booking tab
        ),
        title: const Text('AC Services'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expert AC Care', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        SizedBox(height: 8),
                        Text('Professional servicing, repair, and installation.', style: TextStyle(fontSize: 14, color: AppColors.primaryMid)),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.ac_unit, size: 48, color: AppColors.primaryMid),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Select Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            _buildServiceOption(context, 'AC Installation', 'Professional setup & mounting', Icons.build),
            const SizedBox(height: 16),
            _buildServiceOption(context, 'AC Removal', 'Safe uninstallation & packing', Icons.remove_circle_outline),
            const SizedBox(height: 16),
            _buildServiceOption(context, 'Book A Complaint', 'Quick repair & servicing', Icons.report_problem),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(BuildContext context, String title, String subtitle, IconData icon) {
    return GestureDetector(
      onTap: () => _bookService(context, title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: AppColors.primaryMid),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryMid),
          ],
        ),
      ),
    );
  }
}
