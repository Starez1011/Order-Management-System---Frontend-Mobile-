import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String orderNumber;
  const PaymentScreen({super.key, required this.orderNumber});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Map<String, dynamic>? paymentDetails;
  bool isLoading = true;
  double pointsToUse = 0;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.previewPayment(widget.orderNumber, pointsToUse);
      if (res['success'] == true) {
        setState(() => paymentDetails = res['data']);
        if (pointsToUse == 0 && res['data']['available_points'] > 0) {
          // Initialize UI if needed
        }
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onSliderChanged(double val) {
    setState(() {
      pointsToUse = val.roundToDouble();
    });
  }

  void _applyPoints() {
    _fetchPreview();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && paymentDetails == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final p = paymentDetails!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Payment & Loyalty')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Order #${p['order_number']}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bill Total:', style: TextStyle(fontSize: 18)),
                Text('Rs ${p['total_amount']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            
            // Loyalty Wallet Secton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFA7F3D0))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('💳 Loyalty Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${p['available_points']} points', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('1 point = Rs ${p['point_value']}', style: TextStyle(color: Color(0xFF34D399), fontSize: 13)),
                  
                  const SizedBox(height: 16),
                  if (p['available_points'] > 0) ...[
                    Text('Select points to redeem: ${pointsToUse.toInt()}'),
                    Slider(
                      value: pointsToUse,
                      min: 0,
                      max: p['available_points'].toDouble(),
                      divisions: p['available_points'] > 0 ? p['available_points'].toInt() : 1,
                      onChanged: _onSliderChanged,
                      onChangeEnd: (_) => _applyPoints(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Discount Applied:', style: TextStyle(fontSize: 16, color: Colors.green)),
                Text('- Rs ${p['discount_amount']}', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Final Payable:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Rs ${p['cash_payable']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            Text('You will earn ${p['points_to_earn']} pts after this payment', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : () {
                // Customer asks admin to confirm payment
                showDialog(
                  context: context, 
                  builder: (_) => AlertDialog(
                    title: const Text('Proceed to counter'),
                    content: const Text('Please pay the final amount at the counter. The cashier will confirm your payment and add the earned points to your wallet!'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  )
                );
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Request Payment Confirmation', style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}
