import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_state.dart';
import 'location_picker_screen.dart';
import '../theme/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _pinnedLocation = "No location pinned";

  @override
  void initState() {
    super.initState();
    _mobileController.text = AppState().currentMobileNumber;
  }

  void _openMapToPinLocation() async {
    final LatLng? picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _pinnedLocation = "${picked.latitude.toStringAsFixed(6)},${picked.longitude.toStringAsFixed(6)}";
      });
    }
  }

  void _saveProfile() {
    if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
      
      AppState().updateProfile(UserProfile(
        name: _nameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        address: _addressController.text,
        mapLocation: _pinnedLocation == "No location pinned" ? "" : _pinnedLocation,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Name and Address')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primaryMid, width: 2), borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primaryMid, width: 2), borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.phone,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primaryMid, width: 2), borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Detailed Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primaryMid, width: 2), borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text('Location: $_pinnedLocation', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  onPressed: _openMapToPinLocation,
                  icon: const Icon(Icons.pin_drop, color: Colors.white),
                  label: const Text('Pin on Map', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMid,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Profile & Continue', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
