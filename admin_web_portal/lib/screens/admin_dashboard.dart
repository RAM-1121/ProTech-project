import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'tabs/overview_page.dart';
import 'tabs/work_order_page.dart';
import 'tabs/employee_page.dart';
import 'tabs/plans_page.dart';
import 'tabs/profile_page.dart';
import 'tabs/settings_page.dart';
import '../widgets/notification_bell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int _workOrderInitialIndex = 0;
  int _employeeInitialIndex = 0;
  XFile? _globalProfileImage;

  List<Widget> get _pages => [
        OverviewPage(
          onNavigateToEmployees: (int subIndex) {
            setState(() {
              _selectedIndex = 2; // Index 2 is Employees
              _employeeInitialIndex = subIndex;
            });
          },
          onNavigateToWorkOrders: (int subIndex) {
            setState(() {
              _selectedIndex = 1; // Index 1 is Work Orders
              _workOrderInitialIndex = subIndex;
            });
          },
        ),
        WorkOrderPage(
          key: ValueKey(_workOrderInitialIndex),
          initialIndex: _workOrderInitialIndex,
        ),
        EmployeePage(
          key: ValueKey(_employeeInitialIndex),
          initialIndex: _employeeInitialIndex,
        ),
        const PlansPage(),
        const SettingsPage(),
        ProfilePage(
          currentImage: _globalProfileImage,
          onSaveImage: (newImage) {
            setState(() {
              _globalProfileImage = newImage;
            });
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Soft premium background
      body: Row(
        children: [
          // Premium Sidebar
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E293B), // Deep Slate / Navy
                  Color(0xFF0F172A), // Darker Navy
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(4, 0),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Row(
                    children: [
                      Icon(Icons.ac_unit, color: Colors.blueAccent, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ProTech Cooling Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildNavItem(Icons.dashboard_rounded, 'Overview', 0),
                _buildNavItem(Icons.assignment_rounded, 'Work Orders', 1),
                _buildNavItem(Icons.people_alt_rounded, 'Employees', 2),
                _buildNavItem(
                    Icons.request_quote_rounded, 'Plans / Tariffs', 3),
                _buildNavItem(Icons.settings_rounded, 'Settings', 4),
                const Spacer(),
                const Divider(color: Colors.white24, height: 1),
                _buildNavItem(Icons.person_rounded, 'Profile', 5),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _pages[_selectedIndex],
                ),
                Positioned(
                  top: 32,
                  right: 32,
                  child: NotificationBell(
                    onNavigate: (int mainIndex, int subIndex) {
                      setState(() {
                        _selectedIndex = mainIndex;
                        if (mainIndex == 1) {
                          _workOrderInitialIndex = subIndex;
                        } else if (mainIndex == 2) {
                          _employeeInitialIndex = subIndex;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    return HoverableNavItem(
      icon: icon,
      title: title,
      index: index,
      isSelected: _selectedIndex == index,
      globalProfileImage: index == 5 ? _globalProfileImage : null,
      onTap: () {
        setState(() {
          _selectedIndex = index;
          if (index == 1) {
            _workOrderInitialIndex = 0; // Reset sub-tabs on main navigation
          }
          if (index == 2) {
            _employeeInitialIndex = 0;
          }
        });
      },
    );
  }
}

class HoverableNavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final int index;
  final bool isSelected;
  final XFile? globalProfileImage;
  final VoidCallback onTap;

  const HoverableNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.index,
    required this.isSelected,
    this.globalProfileImage,
    required this.onTap,
  });

  @override
  State<HoverableNavItem> createState() => _HoverableNavItemState();
}

class _HoverableNavItemState extends State<HoverableNavItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final isProfile = widget.index == 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.blueAccent.withValues(alpha: 0.15)
                    : _isHovered
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Colors.blueAccent.withValues(alpha: 0.5)
                      : _isHovered
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  // Active indicator pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 4 : 0,
                    height: 20,
                    margin: EdgeInsets.only(right: isActive ? 12 : 0),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ]),
                  ),

                  // Icon or Profile Image
                  if (isProfile && widget.globalProfileImage != null)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.white24,
                        backgroundImage: kIsWeb
                            ? NetworkImage(widget.globalProfileImage!.path)
                            : FileImage(File(widget.globalProfileImage!.path))
                                as ImageProvider,
                      ),
                    )
                  else
                    Icon(
                      widget.icon,
                      color: isActive
                          ? Colors.blueAccent
                          : (_isHovered ? Colors.white : Colors.white70),
                      size: 22,
                      shadows: isActive
                          ? [
                              Shadow(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                blurRadius: 8,
                              )
                            ]
                          : [],
                    ),

                  SizedBox(width: isActive ? 4 : 16),

                  // Title text
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : (_isHovered ? Colors.white : Colors.white70),
                        fontSize: 15,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      child: Text(widget.title),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
