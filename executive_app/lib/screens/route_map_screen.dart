import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;


class RouteMapScreen extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final String customerName;

  const RouteMapScreen({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.customerName,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  List<LatLng> routePoints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      final start = widget.startLocation;
      final end = widget.endLocation;
      
      // OSRM expects coordinates as lon,lat
      final url = Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List routes = data['routes'] ?? [];
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final List coordinates = geometry['coordinates'] ?? [];
          
          final points = coordinates.map((coord) {
            // GeoJSON provides lon, lat. LatLng expects lat, lon.
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();
          
          setState(() {
            routePoints = points;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bounds to fit both points on screen
    final bounds = LatLngBounds.fromPoints([widget.startLocation, widget.endLocation]);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Route to ${widget.customerName}'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.executive_app',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.startLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.two_wheeler,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                  Marker(
                    point: widget.endLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
