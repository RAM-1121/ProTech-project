import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class RefrigeratorServicesScreen extends StatefulWidget {
  const RefrigeratorServicesScreen({super.key});

  @override
  State<RefrigeratorServicesScreen> createState() => _RefrigeratorServicesScreenState();
}

class _RefrigeratorServicesScreenState extends State<RefrigeratorServicesScreen> {
  bool _showItems = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showItems = true);
      }
    });
  }

  void _bookService(BuildContext context) async {
    final profile = AppState().profileNotifier.value;
    if (profile.name.isEmpty || profile.name == 'Guest User' || profile.name == 'Guest' || profile.mapLocation.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Profile Incomplete'),
          content: const Text('Please complete your profile including your name and map location before booking a service.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
              child: const Text('Complete Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Generate order and save to state
    final orderId = await AppState().addOrder('R', 'Book A Complaint');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Confirmed'),
        content: Text('Booking Order ID $orderId\nYour complain Has Booked. Thank You For Booking Your Services With Protech Cooling Solutions'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
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
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context), // Go back to Booking tab
        ),
        title: const Text(
          'Refrigerator Services',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
                        Text('Refrigerator Care', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                        SizedBox(height: 8),
                        Text('Fast and reliable diagnostics\nand repair services.', style: TextStyle(fontSize: 14, color: AppColors.primaryMid)),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.kitchen, size: 48, color: AppColors.primaryDark),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Select Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
                index: 0,
                child: _buildServiceOption(context, 'Book A Complaint', 'Diagnostic & repair services', Icons.report_problem),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWrapper({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _showItems ? 1.0 : 0.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, val, animatedChild) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildServiceOption(BuildContext context, String title, String subtitle, IconData icon) {
    return GestureDetector(
      onTap: () => _bookService(context),
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
                color: AppColors.primarySoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}
