import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../models/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _mobileController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _useBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkIfAlreadyLoggedIn();
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _auth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }

  Future<void> _checkIfAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMobile = prefs.getString('saved_mobile');
    final useBiometrics = prefs.getBool('use_biometrics') ?? false;

    if (mounted) {
      setState(() {
        _useBiometrics = useBiometrics;
      });
    }

    if (savedMobile != null && savedMobile.isNotEmpty) {
      if (useBiometrics && _canCheckBiometrics) {
        bool authenticated = false;
        try {
          authenticated = await _auth.authenticate(
            localizedReason: 'Please authenticate to log in',
            biometricOnly: false,
          );
        } catch (e) {
          debugPrint('Error authenticating: $e');
        }

        if (authenticated) {
          _mobileController.text = savedMobile;
          _login(skipBiometricPrompt: true);
        } else {
          // If biometric fails, they can still login via OTP
          _mobileController.text = savedMobile;
        }
      } else {
        _mobileController.text = savedMobile;
      }
    }
  }

  Future<String?> _showOtpDialog() async {
    final otpController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit OTP (e.g. 123456)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, otpController.text),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _login({bool skipBiometricPrompt = false}) async {
    if (_mobileController.text.length == 10) {
      final mobile = _mobileController.text;
      bool success = false;

      if (skipBiometricPrompt) {
        success = await context.read<AuthProvider>().verifyOtp(mobile, '123456');
      } else {
        final otpSent = await context.read<AuthProvider>().sendOtp(mobile);
        if (!mounted) return;
        if (otpSent) {
          final otp = await _showOtpDialog();
          if (otp != null && otp.isNotEmpty) {
            if (!mounted) return;
            success = await context.read<AuthProvider>().verifyOtp(mobile, otp);
          } else {
            return; // User cancelled OTP dialog
          }
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to send OTP'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      
      if (success) {
        AppState().setMobileNumber(mobile);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_mobile', mobile);
        
        if (!mounted) return;
        
        void navigateNext() {
          if (prefs.getBool('is_registered') ?? false) {
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            Navigator.pushReplacementNamed(context, '/register');
          }
        }

        if (!skipBiometricPrompt && _canCheckBiometrics) {
          // Prompt to enable biometrics
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Enable Fast Login'),
              content: const Text('Would you like to enable Face ID / Fingerprint / PIN for faster login next time?'),
              actions: [
                TextButton(
                  onPressed: () {
                    prefs.setBool('use_biometrics', false);
                    Navigator.pop(dialogContext);
                    navigateNext();
                  },
                  child: const Text('No Thanks'),
                ),
                ElevatedButton(
                  onPressed: () {
                    prefs.setBool('use_biometrics', true);
                    Navigator.pop(dialogContext);
                    navigateNext();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMid),
                  child: const Text('Enable', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        } else {
          navigateNext();
        }
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Login failed'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Enter a valid 10-digit mobile number'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Premium Logo Area
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.ac_unit, size: 60, color: AppColors.primaryMid),
              ),
              const SizedBox(height: 32),
              const Text(
                'Protech Cooling Solutions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter Mobile Number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    prefixText: '🇮🇳 +91   ',
                    prefixStyle: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.primaryDark
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMid,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Send OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_useBiometrics) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_canCheckBiometrics) {
                      _login(skipBiometricPrompt: true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not available')));
                    }
                  },
                  icon: const Icon(Icons.fingerprint, color: AppColors.primaryMid),
                  label: const Text(
                    'Instant Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryMid,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  _mobileController.text = '9000000001';
                  _login(skipBiometricPrompt: true);
                },
                icon: const Icon(Icons.developer_mode, color: AppColors.primaryMid),
                label: const Text(
                  'Developer Fast Login',
                  style: TextStyle(
                    color: AppColors.primaryMid,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
