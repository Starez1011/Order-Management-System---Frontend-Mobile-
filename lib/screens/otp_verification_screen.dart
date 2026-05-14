import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String otp = '';
  bool isLoading = false;
  int countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    setState(() => countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() => countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void handleVerify(String phone) async {
    if (otp.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.verifyOtp(phone, otp);
      if (res['success'] == true) {
        // Navigate to Setup Profile Screen to finish registration
        Navigator.pushReplacementNamed(context, '/setup_profile', arguments: phone);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      print('Verify OTP Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error verifying OTP')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void handleResendOtp(String phone) async {
    if (countdown > 0) return;
    setState(() => isLoading = true);
    try {
      final res = await ApiService.sendOtp(phone);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new OTP has been sent.')));
        startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      print('Resend OTP Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error resending OTP')));
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
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.message, size: 80, color: Color(0xFF059669)),
              const SizedBox(height: 16),
              Text(
                'We sent an OTP to\n$phone',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => otp = v,
                onSubmitted: (_) => handleVerify(phone),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : () => handleVerify(phone),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify OTP'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: (countdown > 0 || isLoading) ? null : () => handleResendOtp(phone),
                child: Text(
                  countdown > 0 ? 'Resend OTP in ${countdown}s' : 'Resend OTP',
                  style: TextStyle(
                    color: countdown > 0 ? Colors.grey : Color(0xFF059669),
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
