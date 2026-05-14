import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PasswordLoginScreen extends StatefulWidget {
  const PasswordLoginScreen({super.key});

  @override
  State<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends State<PasswordLoginScreen> {
  String password = '';
  bool isLoading = false;
  bool isPasswordVisible = false;

  void handleLogin(String phone) async {
    if (password.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.login(phone, password);
      if (res['success'] == true) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      print('Password Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error verifying password')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock, size: 80, color: Color(0xFF059669)),
              const SizedBox(height: 16),
              Text(
                'Welcome back!\n$phone',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.password),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !isPasswordVisible,
                onChanged: (v) => password = v,
                onSubmitted: (_) => handleLogin(phone),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : () => handleLogin(phone),
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
