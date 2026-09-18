import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Receive Tasks Instantly',
      'description':
          'Get notified as soon as a new customer complaint is assigned to you by the Admin.',
      'icon': 'assignment',
    },
    {
      'title': 'Track Your Earnings',
      'description':
          'Earn reward points for every completed task and redeem them for bonuses.',
      'icon': 'account_balance_wallet',
    },
    {
      'title': 'Manage Availability',
      'description':
          'Easily go online when you are ready to work, or request leave directly from the app.',
      'icon': 'event_available',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_outlined;
      case 'event_available':
        return Icons.event_available_outlined;
      default:
        return Icons.star_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(data['icon']!),
                            size: 100,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 64),
                        Text(
                          data['title']!,
                          style: theme.textTheme.displayLarge
                              ?.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data['description']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _currentPage == _onboardingData.length - 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        child: const Text('Get Started',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Next'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
