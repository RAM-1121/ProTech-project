import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../services/permission_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    if (_isFetchingLocation) return;
    
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
        return;
      }

      final hasPermission = await PermissionService().requestLocationPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      } 

      Position position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _pickedLocation = point;
        });
        _mapController.move(point, 15.0);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location access was denied or failed.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _pickedLocation);
              },
            )
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(17.3850, 78.4867), // Default Hyderabad
          initialZoom: 13.0,
          onTap: (tapPosition, point) {
            setState(() {
              _pickedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.customer_app',
          ),
          if (_pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickedLocation!,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in_btn',
            onPressed: () {
              _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
            },
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.add, color: Colors.black),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out_btn',
            onPressed: () {
              _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
            },
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.remove, color: Colors.black),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'loc_btn',
            onPressed: _getCurrentLocation,
            backgroundColor: AppColors.surface,
            child: const Icon(Icons.my_location, color: AppColors.primaryMid),
          ),
          if (_pickedLocation != null) ...[
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              heroTag: 'confirm_btn',
              onPressed: () {
                Navigator.pop(context, _pickedLocation);
              },
              backgroundColor: AppColors.primaryMid,
              label: const Text('Confirm Location', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.check, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
