import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SendPointsScreen extends StatefulWidget {
  const SendPointsScreen({super.key});

  @override
  State<SendPointsScreen> createState() => _SendPointsScreenState();
}

class _SendPointsScreenState extends State<SendPointsScreen> {
  final _phoneController = TextEditingController();
  final _pointsController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  String? recipientName;
  bool useBiometrics = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      useBiometrics = prefs.getBool('use_biometric_transfer') ?? false;
    });
  }

  void _scanQR() async {
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const P2PScannerScreen()),
    );
    if (scannedData != null && scannedData is String) {
      if (scannedData.startsWith('TRANSFER:')) {
        final parts = scannedData.split(':');
        if (parts.length >= 3) {
          setState(() {
            _phoneController.text = parts[1];
            recipientName = parts[2];
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code format for points transfer.')),
        );
      }
    }
  }

  Future<void> _sendPoints() async {
    final phone = _phoneController.text.trim();
    final pointsText = _pointsController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || pointsText.isEmpty || (!useBiometrics && password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final points = double.tryParse(pointsText);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid points amount')));
      return;
    }

    if (useBiometrics) {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to confirm point transfer',
      );
      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed')));
        return;
      }
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.transferPoints(phone, points, transactionPassword: password, biometricVerified: useBiometrics);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Points sent successfully!')));
        Navigator.pop(context); // Go back to profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Points')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.send_to_mobile, size: 64, color: Color(0xFF059669)),
            const SizedBox(height: 24),
            
            OutlinedButton.icon(
              onPressed: _scanQR,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            
            const SizedBox(height: 24),
            const Text('OR ENTER DETAILS MANUALLY', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 24),

            if (recipientName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Sending to: $recipientName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Recipient Phone Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pointsController,
              decoration: const InputDecoration(labelText: 'Amount to Send (Points)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (!useBiometrics)
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Transaction Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _sendPoints,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Points', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class P2PScannerScreen extends StatefulWidget {
  const P2PScannerScreen({super.key});

  @override
  State<P2PScannerScreen> createState() => _P2PScannerScreenState();
}

class _P2PScannerScreenState extends State<P2PScannerScreen> {
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => isProcessing = true);
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
