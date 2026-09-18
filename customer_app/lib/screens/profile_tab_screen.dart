import 'package:flutter/material.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('My Account'),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('Booking History'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
               // Handle logout
            },
          ),
        ],
      ),
    );
  }
}
