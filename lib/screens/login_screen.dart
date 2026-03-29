import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String phone = '';
  String otp = '';
  bool isOtpSent = false;
  bool isLoading = false;

  void handleSendOtp() async {
    if (phone.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.sendOtp(phone);
      if (res['success'] == true) {
        setState(() => isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending OTP')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void handleVerifyOtp() async {
    if (otp.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.verifyOtp(phone, otp);
      if (res['success'] == true) {
        Navigator.pushReplacementNamed(context, '/qr_scanner');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error verifying OTP')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Register')),
      body: Padding(
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
              enabled: !isOtpSent,
            ),
            if (isOtpSent) ...[
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => otp = v,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : (isOtpSent ? handleVerifyOtp : handleSendOtp),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isOtpSent ? 'Verify OTP' : 'Send OTP'),
            )
          ],
        ),
      ),
    );
  }
}
