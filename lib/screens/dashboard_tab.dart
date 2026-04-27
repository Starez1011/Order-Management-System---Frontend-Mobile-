import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool isLoading = true;
  Map<String, dynamic>? cafeDetails;
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final futures = await Future.wait([
        ApiService.getCafeDetails(),
        ApiService.getMenu(),
      ]);

      final cafeRes = futures[0];
      final menuRes = futures[1];

      if (mounted) {
        setState(() {
          if (cafeRes['success'] == true) {
            cafeDetails = cafeRes['data'];
          }
          if (menuRes['success'] == true) {
            categories = menuRes['data'];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print('Dashboard Fetch Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigoAccent),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: Colors.indigoAccent,
      child: CustomScrollView(
        slivers: [
          // Modern Cafe Details Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cafeDetails?['name'] ?? 'The Café',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (cafeDetails?['address'] != null && cafeDetails!['address'].toString().isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cafeDetails!['address'],
                            style: const TextStyle(
                              color: Colors.white70, 
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (cafeDetails?['phone_number'] != null && cafeDetails!['phone_number'].toString().isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          cafeDetails!['phone_number'],
                          style: const TextStyle(
                            color: Colors.white70, 
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                  // Fancy QR Call to Action
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.indigo, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ready to order?',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tap the camera button below to scan your table.',
                                style: TextStyle(
                                  color: Colors.white70, 
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Menu Title Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  const Text(
                    'Explore Menu',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B), // Slate 800
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.restaurant_menu_rounded, color: Colors.indigo.shade300),
                ],
              ),
            ),
          ),

          // Menu Categories (Horizontal Scroll for each category)
          if (categories.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No menu items available.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, categoryIndex) {
                  final category = categories[categoryIndex];
                  final items = category['items'] as List<dynamic>? ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                        child: Text(
                          category['name'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade400,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      // Horizontal Items List
                      SizedBox(
                        height: 220, // Fixed height for horizontal cards
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, itemIndex) {
                            final item = items[itemIndex];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image top half
                                  Expanded(
                                    flex: 3,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                      ),
                                      child: item['image'] != null
                                          ? Image.network(
                                              item['image'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
                                            )
                                          : _buildPlaceholder(),
                                    ),
                                  ),
                                  // Text bottom half
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if (item['description'] != null && item['description'].toString().isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                item['description'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  height: 1.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                childCount: categories.length,
              ),
            ),
            
          // Padding for the Bottom Navigation and FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.indigo.shade50,
      child: Center(
        child: Icon(
          Icons.fastfood_rounded, 
          color: Colors.indigo.shade200, 
          size: 32
        ),
      ),
    );
  }
}
