import 'package:flutter/material.dart';
import 'customer_dashboard_screen.dart';
import 'map_tracking_screen.dart';
import 'profile_tab_screen.dart';
import '../theme/app_colors.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CustomerDashboardScreen(),
    const MapTrackingScreen(),
    const ProfileTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 16.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_repair_service, 'Booking'),
                    _buildNavItem(1, Icons.track_changes, 'Tracking'),
                    _buildNavItem(2, Icons.person_outline, 'Profile'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              top: isSelected ? -20 : 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: isSelected ? 56 : 24,
                height: isSelected ? 56 : 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDark : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey,
                  size: isSelected ? 28 : 24,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 350),
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter', // Default text style family to prevent default fallback issues
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primaryDark : Colors.grey,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
