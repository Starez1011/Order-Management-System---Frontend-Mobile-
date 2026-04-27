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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading menu')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addToCart(int itemId) async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.currentQrToken == null) return;
    
    try {
      final res = await ApiService.addToCart(state.currentQrToken!, itemId, 1);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
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
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
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
                  onPressed: item['is_available'] ? () => _addToCart(item['id']) : null,
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
