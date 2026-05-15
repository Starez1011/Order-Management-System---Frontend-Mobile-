import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'cart_screen.dart';

// ─── Shared app colors (green theme) ─────────────────────────────────────────
const kPrimary   = Color(0xFF059669); // emerald-600
const kPrimaryDk = Color(0xFF064E3B); // emerald-950
const kPrimaryLt = Color(0xFFD1FAE5); // emerald-100
const kSurface   = Color(0xFFF0FDF4); // emerald-50
const kText      = Color(0xFF1E293B);
const kTextMuted = Color(0xFF64748B);

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  List<dynamic> categories = [];
  bool isLoading = true;
  int _fetchVersion = 0;     // incremented per fetch; stale results are discarded
  int cartItemCount = 0;
  int? _branchId;        // currently loaded branch id
  String? _branchName;   // display name for AppBar subtitle
  AppState? _appState;   // reference for addListener / removeListener

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Wire up AppState listener once
    final appState = Provider.of<AppState>(context, listen: false);
    if (_appState != appState) {
      _appState?.removeListener(_onBranchChanged);
      _appState = appState;
      _appState!.addListener(_onBranchChanged);
    }
    // NOTE: do NOT call _refreshIfBranchChanged() here.
    // initState already calls _loadAndFetch(); calling it again here
    // causes two concurrent fetches → TabController disposed twice → exception.
  }

  void _onBranchChanged() {
    final newId = _appState?.selectedBranchId;
    if (newId != null && newId != _branchId) {
      _loadAndFetch();
    }
  }

  /// Re-load only if the saved branch differs from what we currently show.
  Future<void> _refreshIfBranchChanged() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt('last_selected_branch_id');
    if (savedId != null && savedId != _branchId) {
      await _loadAndFetch();
    }
  }

  Future<void> _loadAndFetch() async {
    final version = ++_fetchVersion;  // this fetch's identity
    if (mounted) setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final branchId   = prefs.getInt('last_selected_branch_id');
    final branchName = prefs.getString('last_selected_branch_name');
    if (mounted && version == _fetchVersion) {
      setState(() {
        _branchId   = branchId;
        _branchName = branchName;
      });
    }
    await _fetchMenu(branchId, version);
  }

  Future<void> _fetchMenu([int? branchId, int? version]) async {
    final id = branchId ?? _branchId;
    if (id == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final res = await ApiService.getMenu(id);
      // Discard stale results if a newer fetch has started
      final isLatest = version == null || version == _fetchVersion;
      if (res['success'] == true && mounted && isLatest) {
        final cats = (res['data'] as List<dynamic>)
            .where((c) => (c['items'] as List<dynamic>?)?.isNotEmpty == true)
            .toList();
        setState(() {
          categories = cats;
        });
      }
    } catch (e, st) {
      debugPrint('Menu fetch error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load menu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
    _fetchCartCount();
  }

  Future<void> _fetchCartCount() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.currentQrToken == null) return;
    try {
      final res = await ApiService.getCart(state.currentQrToken!);
      if (res['success'] == true && mounted) {
        final items = res['data']['items'] as List;
        setState(() => cartItemCount = items.fold(0, (s, i) => s + (i['quantity'] as int)));
      }
    } catch (_) {}
  }

  Future<void> _addToCart(int itemId) async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.currentQrToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan a table QR first to add items.')),
      );
      return;
    }
    try {
      await ApiService.addToCart(state.currentQrToken!, itemId, 1);
      _fetchCartCount();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to cart!'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _appState?.removeListener(_onBranchChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: kSurface,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (_branchId == null) {
      return Scaffold(
        backgroundColor: kSurface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_rounded, size: 64, color: kPrimary.withOpacity(0.4)),
              const SizedBox(height: 16),
              const Text('No branch selected.', style: TextStyle(color: kTextMuted, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Go to the Home tab and choose a branch.', style: TextStyle(color: kTextMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return Scaffold(
        backgroundColor: kSurface,
        appBar: _buildAppBar(null),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 64, color: kPrimary.withOpacity(0.4)),
              const SizedBox(height: 16),
              const Text('No menu available for this branch.', style: TextStyle(color: kTextMuted, fontSize: 16)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _loadAndFetch,
                icon: const Icon(Icons.refresh, color: kPrimary),
                label: const Text('Retry', style: TextStyle(color: kPrimary)),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: _buildAppBar(
          TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: kPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: categories.map((c) => Tab(text: c['name'].toString())).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((category) {
          final items = category['items'] as List<dynamic>? ?? [];
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: _loadAndFetch,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _MenuItemCard(item: item, onAddToCart: () => _addToCart(item['id']));
              },
            ),
          );
        }).toList(),
      ),
    ),
    );
  }

  PreferredSizeWidget _buildAppBar(PreferredSizeWidget? bottom) {
    return AppBar(
      backgroundColor: kPrimaryDk,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          if (_branchName != null && _branchName!.isNotEmpty)
            Text(
              _branchName!,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        if (cartItemCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ).then((_) => _fetchCartCount()),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      bottom: bottom,
    );
  }
}

// ─── Menu Item Card ────────────────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onAddToCart;

  const _MenuItemCard({required this.item, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final hasImage = item['image_url'] != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: hasImage
                  ? Image.network(
                      ApiService.getImageUrl(item['image_url']),
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + optional Global badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item['is_global'] == true)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimaryLt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Global', style: TextStyle(fontSize: 10, color: kPrimary, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
                      style: const TextStyle(fontSize: 13, color: kTextMuted, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['discounted_price'] != null)
                            Row(
                              children: [
                                Text(
                                  'Rs ${item['price']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted, decoration: TextDecoration.lineThrough),
                                ),
                                if (item['discount_percentage'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text('-${item['discount_percentage']}%', style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w800)),
                                  ),
                              ],
                            ),
                          Text(
                            'Rs ${item['discounted_price'] ?? item['price']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: kPrimaryLt,
        child: const Center(child: Icon(Icons.fastfood_rounded, color: kPrimary, size: 32)),
      );
}
