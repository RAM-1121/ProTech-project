import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ElectricianServicesScreen extends StatefulWidget {
  const ElectricianServicesScreen({super.key});

  @override
  State<ElectricianServicesScreen> createState() => _ElectricianServicesScreenState();
}

class _ElectricianServicesScreenState extends State<ElectricianServicesScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Electrician Services',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _showItems ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - val)),
                child: Opacity(
                  opacity: val,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.electrical_services, size: 64, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Coming Soon!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stay tuned for more updates.\nWe are working hard to bring you expert electrical services.',
                    style: TextStyle(fontSize: 16, color: AppColors.textMuted, height: 1.5),
                    textAlign: TextAlign.center,
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
