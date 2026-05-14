import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List;
    final date = DateTime.tryParse(order['created_at']);
    final formattedDate = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';
    final bool paidWithPoints = order['paid_with_points'] ?? false;
    final pointsUsed = order['points_used'] ?? 0;
    final pointsEarned = order['points_earned'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Number', style: TextStyle(color: Colors.grey)),
                        Text(order['order_number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Date', style: TextStyle(color: Colors.grey)),
                        Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Table', style: TextStyle(color: Colors.grey)),
                        Text(order['table_number'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (order['branch_name'] != null && order['branch_name'] != 'Unknown') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Branch', style: TextStyle(color: Colors.grey)),
                          Text(order['branch_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status', style: TextStyle(color: Colors.grey)),
                        Text(_formatStatus(order['status']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Items List
            const Text('Items Ordered', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, i) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                              child: Text('${item['quantity']}x', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text('Rs ${item['line_total']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Payment Summary
            const Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 16)),
                        Text('Rs ${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    if (order['payment_method'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method', style: TextStyle(color: Colors.grey)),
                          Text(order['payment_method'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    if (paidWithPoints) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.stars, color: Colors.orange, size: 18),
                              SizedBox(width: 6),
                              Text('Paid with Loyalty Points', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text('-$pointsUsed pts', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_circle, color: Colors.green, size: 18),
                            SizedBox(width: 6),
                            Text('Points Earned', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Text('+$pointsEarned pts', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
