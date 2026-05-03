import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> categories = [];
  bool isLoading = true;
  int cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final res = await ApiService.getMenu();
      if (res['success'] == true) {
        setState(() => categories = res['data']);
      }
      _fetchCartCount();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading menu')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCartCount() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.currentQrToken == null) return;
    try {
      final res = await ApiService.getCart(state.currentQrToken!);
      if (res['success'] == true) {
        final items = res['data']['items'] as List;
        int count = 0;
        for (var item in items) {
          count += (item['quantity'] as int);
        }
        setState(() => cartItemCount = count);
      }
    } catch (e) {
      // ignore
    }
  }

  void _showQuantityDialog(dynamic item) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add ${item['name']}'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantity > 1 ? () => setDialogState(() => quantity--) : null,
                  ),
                  Text('$quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setDialogState(() => quantity++),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart(item['id'], quantity);
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _addToCart(int itemId, int quantity) async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.currentQrToken == null) return;
    
    try {
      final res = await ApiService.addToCart(state.currentQrToken!, itemId, quantity);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
        _fetchCartCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Café Menu'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())).then((_) => _fetchCartCount()),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final category = categories[i];
          final items = category['items'];
          
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.indigo.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(category['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
              ...items.map<Widget>((item) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Rs ${item['price']}\n${item['description']}'),
                isThreeLine: true,
                trailing: ElevatedButton(
                  onPressed: item['is_available'] ? () => _showQuantityDialog(item) : null,
                  child: Text(item['is_available'] ? 'Add' : 'Out'),
                ),
              )).toList(),
            ],
          );
        },
      ),
    );
  }
}
