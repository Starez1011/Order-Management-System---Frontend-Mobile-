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

  // Slider logic removed as per user request

  @override
  Widget build(BuildContext context) {
    if (isLoading && paymentDetails == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final p = paymentDetails!;
    
    List<String> affordableItems = [];
    List<Widget> itemWidgets = [];
    if (p['items'] != null) {
      for (var item in p['items']) {
        int pointsNeeded = (item['line_total'] / p['point_value']).ceil();
        int pointsPerItem = (item['price'] / p['point_value']).ceil();
        
        if (p['available_points'] >= pointsNeeded) {
          affordableItems.add("${item['quantity']}x ${item['name']}");
        } else if (item['quantity'] > 1 && p['available_points'] >= pointsPerItem) {
          int maxAffordableQty = p['available_points'] ~/ pointsPerItem;
          affordableItems.add("$maxAffordableQty of ${item['name']}");
        }
        itemWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text('${item['quantity']}x ${item['name']}')),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$pointsNeeded pts', style: TextStyle(fontWeight: FontWeight.bold, color: p['available_points'] >= pointsNeeded ? Colors.green : Colors.red)),
                    if (item['quantity'] > 1)
                      Text('(${pointsPerItem} pts / item)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }
    
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
            const SizedBox(height: 16),
            const Text(
              'Check if you have enough loyalty points to pay for this order completely.', 
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87)
            ),
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
                  const SizedBox(height: 16),
                  const Text('Items & Points Required:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...itemWidgets,
                  const Divider(height: 24),
                  
                  Text(
                    'Total points needed: ${(p['total_amount'] / p['point_value']).ceil()}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                  ),
                  if (p['available_points'] >= (p['total_amount'] / p['point_value'])) ...[
                    const SizedBox(height: 8),
                    const Text('✅ You have enough points for the full order!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ] else if (affordableItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '💡 You have enough points to pay for:\n- ${affordableItems.join('\n- ')}\n\nAsk the counter to redeem points for these items and pay the remaining balance yourself.', 
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)
                      ),
                    )
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text('❌ Not enough points for any item.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
