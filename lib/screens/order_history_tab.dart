import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'order_detail_screen.dart';

class OrderHistoryTab extends StatefulWidget {
  const OrderHistoryTab({super.key});

  @override
  State<OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<OrderHistoryTab> {
  List<dynamic> orders = [];
  bool isLoading = true;
  int _selectedFilterDays = 7; // default 7 days

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.getMyOrderHistory(days: _selectedFilterDays);
      if (res['success'] == true) {
        setState(() => orders = res['data']);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to load history')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Show history for:', style: TextStyle(fontWeight: FontWeight.w600)),
              DropdownButton<int>(
                value: _selectedFilterDays,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Last 24 Hours')),
                  DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
                  DropdownMenuItem(value: 90, child: Text('Last 3 Months')),
                  DropdownMenuItem(value: 180, child: Text('Last 6 Months')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedFilterDays = val);
                    _fetchHistory();
                  }
                },
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF059669)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : orders.isEmpty
                  ? Center(child: Text('No orders found for the last $_selectedFilterDays days.', style: const TextStyle(fontSize: 16, color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _fetchHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final order = orders[i];
                          final status = order['status'];
                          final date = DateTime.tryParse(order['created_at']);
                          final formattedDate = date != null
                              ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                              : '';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF0FDF4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.receipt, color: Color(0xFF059669)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(order['order_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          if (order['branch_name'] != null && order['branch_name'] != 'Unknown') ...[
                                            const SizedBox(height: 2),
                                            Text(order['branch_name'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                                          ],
                                          if (order['payment_method'] != null) ...[
                                            const SizedBox(height: 2),
                                            Text(order['payment_method'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Rs ${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF059669))),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(_formatStatus(status), style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
