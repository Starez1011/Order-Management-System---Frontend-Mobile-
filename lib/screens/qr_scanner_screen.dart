import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../main.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool isProcessing = false;

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text('Please enable location services (GPS) to verify your table.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            )
          ],
        )
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text('We need location permission to verify you are at the cafe. Please enable it in App Settings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            )
          ],
        )
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final qrRaw = barcodes.first.rawValue;
      if (qrRaw == null) return;
      
      setState(() => isProcessing = true);
      
      // Handle Payment QR (e.g., PAY:uuid:150)
      if (qrRaw.startsWith('PAY:')) {
        final parts = qrRaw.split(':');
        if (parts.length >= 3) {
          final qrToken = parts[1];
          final pointsString = parts[2];
          
          setState(() => isProcessing = false);
          
          // Show confirmation dialog before deduction
          bool? confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirm Payment'),
              content: Text('Do you want to deduct $pointsString loyalty points for this bill?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm Pay')),
              ],
            )
          );
          
          if (confirm == true) {
            setState(() => isProcessing = true);
            try {
              final res = await ApiService.payViaQr(qrToken);
              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['data']['message'])));
                Navigator.pop(context); // Go back home after success
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
            } finally {
              if (mounted) setState(() => isProcessing = false);
            }
          }
        } else {
          setState(() => isProcessing = false);
        }
        return; // Stop here if it was a payment QR
      }

      // Handle standard Table QR Validation
      try {
        final pos = await _determinePosition();
        if (pos == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission required.')));
          setState(() => isProcessing = false);
          return;
        }

        final res = await ApiService.validateQr(qrRaw, pos.latitude, pos.longitude);
        if (res['success'] == true) {
          final tableNumber = res['data']['table_number'];
          final branchId = res['data']['branch_id'];
          Provider.of<AppState>(context, listen: false).setTableSession(qrRaw, tableNumber, branchId);
          Navigator.pushReplacementNamed(context, '/menu');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
          // Wait briefly before allowing next scan
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
      } finally {
        if(mounted) setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Table QR')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Validating Location...', style: TextStyle(color: Colors.white, fontSize: 18))
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: const Text('Scan QR inside the Café', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
