import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeIdController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _isBiometricSupported = isSupported == true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricSupported = false;
        });
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        if (!mounted) return;
        // Mocking employee ID for biometric login
        final error = await context.read<AuthProvider>().login('E-001', 'executive');
        if (!mounted) return;
        if (error == null) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Login Failed'),
              content: const Text('Invalid Employee ID'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _login() async {
    if (_employeeIdController.text.isNotEmpty) {
      final error = await context.read<AuthProvider>().login(_employeeIdController.text, 'executive');
      if (!mounted) return;
      if (error == null) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Invalid Employee ID'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid Employee ID')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Executive Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Image.asset(
              'assets/images/company_logo.jpg',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Protech Cooling Solutions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _employeeIdController,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),
            if (_isBiometricSupported)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loginWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Login with Biometrics', style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: const BorderSide(color: Colors.blueAccent),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
