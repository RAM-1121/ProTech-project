import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/api_data_provider.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && user['employeeId'] != null) {
        context.read<ApiDataProvider>().fetchMyProfile(user['employeeId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = context.watch<ApiDataProvider>().myProfile;
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profile == null 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile['firstName'] ?? user?['name'] ?? 'Executive Name',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      profile['employeeId'] ?? user?['employeeId'] ?? 'E-001',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF800020)),
                    ),
                    const SizedBox(height: 32),
                    _buildCapsuleCard(Icons.phone, 'Phone Number', profile['phone'] ?? 'N/A'),
                    _buildCapsuleCard(Icons.work, 'Status', profile['status'] ?? 'N/A'),
                    _buildCapsuleCard(Icons.bloodtype, 'Blood Group', profile['bloodGroup'] ?? 'N/A'),
                    _buildCapsuleCard(Icons.calendar_today, 'Date of Joining', profile['doj'] != null ? profile['doj'].toString().split('T')[0] : 'N/A'),
                    _buildCapsuleCard(Icons.star, 'Experience', profile['experience'] ?? 'N/A'),
                    _buildCapsuleCard(Icons.account_balance, 'Bank Details', profile['bankDetails'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildCapsuleCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blueAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF800020))),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF800020), fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
