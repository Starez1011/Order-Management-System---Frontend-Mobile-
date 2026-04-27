import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phone = '';
  bool isLoading = false;

  void handleLogin() async {
    if (phone.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.checkPhone(phone);
      if (res['success'] == true) {
        final exists = res['data']['exists'] == true;
        if (exists) {
          // Navigate to Password Login Screen
          Navigator.pushNamed(context, '/password_login', arguments: phone);
        } else {
          // Navigate to OTP Screen
          Navigator.pushNamed(context, '/otp_verification', arguments: phone);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your phone.')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      print('Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error connecting to server')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.coffee, size: 80, color: Colors.indigo),
              const SizedBox(height: 32),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phone = v,
                onSubmitted: (_) => handleLogin(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
