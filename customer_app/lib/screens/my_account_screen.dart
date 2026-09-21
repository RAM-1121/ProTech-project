import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../models/app_state.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _flatController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _coordinatesController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(28.6139, 77.2090); // Default to New Delhi
  bool _isLoadingLocation = true;
  bool _isEditing = false;
  bool _showItems = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _determineInitialLocation();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _showItems = true);
      }
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? AppState().profileNotifier.value.name;
      _mobileController.text = prefs.getString('saved_mobile') ?? AppState().currentMobileNumber;
      _emailController.text = prefs.getString('user_email') ?? AppState().profileNotifier.value.email;
      
      final addressFlat = prefs.getString('address_flat');
      _flatController.text = addressFlat ?? '';
      _streetController.text = prefs.getString('address_street') ?? '';
      _cityController.text = prefs.getString('address_city') ?? '';
      _pincodeController.text = prefs.getString('address_pincode') ?? '';
      
      if (_flatController.text.isEmpty && _streetController.text.isEmpty && 
          _cityController.text.isEmpty && _pincodeController.text.isEmpty && 
          AppState().profileNotifier.value.address.isNotEmpty) {
        _streetController.text = AppState().profileNotifier.value.address;
      }
      
      final lat = prefs.getDouble('address_lat');
      final lng = prefs.getDouble('address_lng');
      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
        _isLoadingLocation = false;
        // Wait a tick for the map to be ready if it's built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_selectedLocation, 15.0);
        });
      } else if (AppState().profileNotifier.value.mapLocation.isNotEmpty) {
        try {
          final parts = AppState().profileNotifier.value.mapLocation.split(',');
          if (parts.length == 2) {
             _selectedLocation = LatLng(double.parse(parts[0]), double.parse(parts[1]));
             _isLoadingLocation = false;
             WidgetsBinding.instance.addPostFrameCallback((_) {
               _mapController.move(_selectedLocation, 15.0);
             });
          }
        } catch (_) {}
      }
      _coordinatesController.text = "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}";
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_email', _emailController.text.trim());
    await prefs.setString('address_flat', _flatController.text.trim());
    await prefs.setString('address_street', _streetController.text.trim());
    await prefs.setString('address_city', _cityController.text.trim());
    await prefs.setString('address_pincode', _pincodeController.text.trim());
    await prefs.setDouble('user_lat', _selectedLocation.latitude);
    await prefs.setDouble('user_lng', _selectedLocation.longitude);
    
    // Construct full address for AppState
    final parts = [
      _flatController.text.trim(),
      _streetController.text.trim(),
      _cityController.text.trim(),
      _pincodeController.text.trim()
    ].where((part) => part.isNotEmpty);
    
    final uniqueTokens = <String>{};
    for (final p in parts) {
      uniqueTokens.addAll(p.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    final fullAddress = uniqueTokens.join(', ');

    // Also save to AppState so that bookings include the address
    AppState().updateProfile(UserProfile(
      name: _nameController.text.trim(),
      mobile: AppState().currentMobileNumber,
      email: _emailController.text.trim(),
      address: fullAddress,
      mapLocation: "${_selectedLocation.latitude},${_selectedLocation.longitude}",
      profilePicturePath: AppState().profileNotifier.value.profilePicturePath,
    ));

    if (!mounted) return;
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services disabled.')));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied.')));
      }
      return;
    } 

    final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _coordinatesController.text = "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}";
      _isLoadingLocation = false;
    });
    _mapController.move(_selectedLocation, 15.0);
  }

  Future<void> _determineInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    // Only fetch current if we haven't saved one yet
    if (prefs.getDouble('address_lat') == null) {
      await _fetchCurrentLocation();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _coordinatesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit, color: AppColors.primaryMid),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedWrapper(
              index: 0,
              child: _buildSectionTitle('Personal Details'),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 1,
              child: _buildTextField('Full Name', _nameController, !_isEditing, Icons.person_outline),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 2,
              child: _buildTextField('Mobile Number', _mobileController, true, Icons.phone_outlined), // Always Read only
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 3,
              child: _buildTextField('Email Address (Optional)', _emailController, !_isEditing, Icons.email_outlined),
            ),
            
            const SizedBox(height: 32),
            _buildAnimatedWrapper(
              index: 4,
              child: _buildSectionTitle('Address Details'),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 5,
              child: _buildTextField('House / Flat No.', _flatController, !_isEditing, Icons.home_outlined),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 6,
              child: _buildTextField('Street Name', _streetController, !_isEditing, Icons.signpost_outlined),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 7,
              child: _buildTextField('City', _cityController, !_isEditing, Icons.location_city_outlined),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 8,
              child: _buildTextField('Pincode', _pincodeController, !_isEditing, Icons.pin_drop_outlined),
            ),
            const SizedBox(height: 16),
            _buildAnimatedWrapper(
              index: 9,
              child: _buildTextField('Coordinates', _coordinatesController, true, Icons.my_location_outlined),
            ),
            
            const SizedBox(height: 32),
            _buildAnimatedWrapper(
              index: 8,
              child: _buildSectionTitle('Exact Location (Drag map to pin)'),
            ),
            const SizedBox(height: 16),
            
            _buildAnimatedWrapper(
              index: 9,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 15.0,
                        interactionOptions: InteractionOptions(
                          flags: _isEditing ? InteractiveFlag.all : InteractiveFlag.none,
                        ),
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture && _isEditing) {
                            setState(() {
                              _selectedLocation = position.center;
                              _coordinatesController.text = "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}";
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.customer_app',
                        ),
                      ],
                    ),
                    // Center Pin Overlay
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40.0), // Offset to put point of pin at center
                        child: Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    // My Location Button
                    if (_isEditing)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          onPressed: _fetchCurrentLocation,
                          child: const Icon(Icons.my_location, color: AppColors.primaryMid),
                        ),
                      ),
                    if (_isLoadingLocation)
                      Container(
                        color: Colors.white.withValues(alpha: 0.5),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (_isEditing)
              _buildAnimatedWrapper(
                index: 10,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMid.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveProfileData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMid,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            if (_isEditing) const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWrapper({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _showItems ? 1.0 : 0.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, val, animatedChild) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryMid,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isReadOnly, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? AppColors.surface.withValues(alpha: 0.7) : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          if (!isReadOnly)
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        style: TextStyle(
          color: isReadOnly ? AppColors.textMuted : AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isReadOnly ? AppColors.textMuted : AppColors.primaryMid,
          ),
          prefixIcon: Icon(
            icon,
            color: isReadOnly ? AppColors.textMuted : AppColors.primaryMid,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }
}
