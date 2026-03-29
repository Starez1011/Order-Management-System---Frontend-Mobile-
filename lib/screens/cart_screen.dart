import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> items = [];
  double total = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.currentQrToken == null) return;
    try {
      final res = await ApiService.getCart(state.currentQrToken!);
      if (res['success'] == true) {
        setState(() {
          items = res['data']['items'];
          total = res['data']['total'];
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    final state = Provider.of<AppState>(context, listen: false);
    setState(() => isLoading = true);
    try {
      final res = await ApiService.placeOrder(state.currentQrToken!);
      if (res['success'] == true) {
        final orderNum = res['data']['order_number'];
        // Navigate to payment/loyalty screen passing order number
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentScreen(orderNumber: orderNum)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error placing order')));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('Qty: ${item['quantity']} × Rs ${item['price']}'),
                        trailing: Text('Rs ${item['line_total']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Rs $total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _placeOrder,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Place Order', style: TextStyle(fontSize: 18)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
