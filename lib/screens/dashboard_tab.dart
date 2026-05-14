import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../main.dart';

// ─── Shared green palette ──────────────────────────────────────────────────
const kPrimary   = Color(0xFF059669); // emerald-600
const kPrimaryDk = Color(0xFF064E3B); // emerald-950
const kPrimaryMd = Color(0xFF047857); // emerald-700
const kPrimaryLt = Color(0xFFD1FAE5); // emerald-100
const kSurface   = Color(0xFFF0FDF4); // emerald-50
const kText      = Color(0xFF1E293B);
const kTextMuted = Color(0xFF64748B);

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool isLoading = true;
  Map<String, dynamic>? cafeDetails;
  int unreadNotificationsCount = 0;
  List<dynamic> branches = [];
  Map<String, dynamic>? selectedBranch;

  // Promotions data
  List<dynamic> banners = [];
  List<dynamic> offers = [];
  List<dynamic> popularItems = [];

  // Banner auto-scroll
  int _bannerPage = 0;
  Timer? _bannerTimer;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getNearestBranch(List<dynamic> list) async {
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) return list.first;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return list.first;
      }
      Position pos = await Geolocator.getCurrentPosition();
      double minDist = double.infinity;
      Map<String, dynamic> nearest = list.first;
      for (var b in list) {
        double bLat = double.tryParse(b['latitude'].toString()) ?? 0.0;
        double bLon = double.tryParse(b['longitude'].toString()) ?? 0.0;
        double d = Geolocator.distanceBetween(pos.latitude, pos.longitude, bLat, bLon);
        if (d < minDist) { minDist = d; nearest = b; }
      }
      return nearest;
    } catch (_) {
      return list.first;
    }
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Branches
      if (branches.isEmpty) {
        final brRes = await ApiService.getBranches();
        if (brRes['success'] == true) {
          branches = brRes['data'] as List<dynamic>;
          if (branches.isNotEmpty) {
            final savedId = prefs.getInt('last_selected_branch_id');
            if (savedId != null) {
              selectedBranch = branches.firstWhere((b) => b['id'] == savedId, orElse: () => branches.first);
            } else {
              selectedBranch = await _getNearestBranch(branches);
              await prefs.setInt('last_selected_branch_id', selectedBranch!['id']);
              final bName = '${selectedBranch!['restaurant_name']} - ${selectedBranch!['branch_name']}';
              await prefs.setString('last_selected_branch_name', bName);
              if (mounted) {
                Provider.of<AppState>(context, listen: false).setSelectedBranch(selectedBranch!['id'], bName);
              }
            }
          }
        }
      }

      // Parallel: cafe details + notifications + promotions
      if (selectedBranch != null) {
        final results = await Future.wait([
          ApiService.getCafeDetails(selectedBranch!['id']),
          ApiService.getNotifications(),
          ApiService.getBanners(),
          ApiService.getOffers(),
          ApiService.getPopularItems(branchId: selectedBranch!['id']),
        ]);

        if (mounted) {
          setState(() {
            if (results[0]['success'] == true) cafeDetails = results[0]['data'];
            if (results[1]['success'] == true) {
              final notifs = results[1]['data'] as List<dynamic>;
              unreadNotificationsCount = notifs.where((n) => n['is_read'] == false).length;
            }
            if (results[2]['success'] == true) banners = results[2]['data'] as List<dynamic>;
            if (results[3]['success'] == true) offers = results[3]['data'] as List<dynamic>;
            if (results[4]['success'] == true) popularItems = results[4]['data'] as List<dynamic>;
            isLoading = false;
          });
          _startBannerTimer();
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (banners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_bannerPage + 1) % banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: kSurface,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: kPrimary,
      child: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── Banner carousel ────────────────────────────────────────────────
          if (banners.isNotEmpty)
            SliverToBoxAdapter(child: _buildBannerSection()),

          // ── Special Offers ─────────────────────────────────────────────────
          if (offers.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionHeader('🏷️ Special Offers')),
            SliverToBoxAdapter(child: _buildOffersRow()),
          ],

          // ── Most Popular ───────────────────────────────────────────────────
          if (popularItems.isNotEmpty) ...[
            SliverToBoxAdapter(child: _sectionHeader('🔥 Most Popular')),
            SliverToBoxAdapter(child: _buildPopularRow()),
          ],

          // No promotions fallback
          if (banners.isEmpty && offers.isEmpty && popularItems.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.campaign_rounded, size: 56, color: kPrimary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    const Text('No promotions yet.', style: TextStyle(color: kTextMuted, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Check back later for special offers!', style: TextStyle(color: kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryDk, kPrimaryMd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch selector
          if (branches.isNotEmpty && selectedBranch != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  dropdownColor: kPrimaryMd,
                  value: selectedBranch!['id'],
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  onChanged: (int? newId) async {
                    if (newId == null) return;
                    setState(() { selectedBranch = branches.firstWhere((b) => b['id'] == newId); isLoading = true; });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('last_selected_branch_id', newId);
                    final bName2 = '${selectedBranch!['restaurant_name']} - ${selectedBranch!['branch_name']}';
                    await prefs.setString('last_selected_branch_name', bName2);
                    if (mounted) {
                      Provider.of<AppState>(context, listen: false).setSelectedBranch(newId, bName2);
                    }
                    _fetchData();
                  },
                  items: branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem<int>(
                    value: b['id'],
                    child: Text('${b['restaurant_name']} – ${b['branch_name']}'),
                  )).toList(),
                ),
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome to',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500, letterSpacing: 1.2),
              ),
              Stack(clipBehavior: Clip.none, children: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => _fetchData()),
                ),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text(unreadNotificationsCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            cafeDetails?['name'] ?? 'The Café',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
          ),

          if (cafeDetails?['address'] != null && cafeDetails!['address'].toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(cafeDetails!['address'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4))),
              ],
            ),
          ],

          if (cafeDetails?['phone_number'] != null && cafeDetails!['phone_number'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.phone_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(cafeDetails!['phone_number'], style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ],

          const SizedBox(height: 28),

          // QR call to action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code_scanner_rounded, color: kPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ready to order?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 2),
                  Text('Tap the camera button below to scan your table.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText, letterSpacing: -0.3),
      ),
    );
  }

  // ─── Banner carousel ───────────────────────────────────────────────────────
  Widget _buildBannerSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          child: Row(children: const [
            Text('✨ Today\'s Highlights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText, letterSpacing: -0.3)),
          ]),
        ),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (ctx, i) {
              final banner = banners[i];
              return _BannerCard(banner: banner);
            },
          ),
        ),
        if (banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _bannerPage == i ? kPrimary : kPrimaryLt,
                  borderRadius: BorderRadius.circular(99),
                ),
              )),
            ),
          ),
      ],
    );
  }

  // ─── Offers row ────────────────────────────────────────────────────────────
  Widget _buildOffersRow() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: offers.length,
        itemBuilder: (_, i) => _OfferCard(offer: offers[i]),
      ),
    );
  }

  // ─── Popular items row ─────────────────────────────────────────────────────
  Widget _buildPopularRow() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: popularItems.length,
        itemBuilder: (_, i) => _PopularCard(item: popularItems[i]),
      ),
    );
  }
}

// ─── Banner Card ───────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final dynamic banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    final imgUrl = banner['image_url'] as String?;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [kPrimaryDk, kPrimaryMd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: kPrimaryMd.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imgUrl != null && imgUrl.isNotEmpty)
              Image.network(
                ApiService.getImageUrl(imgUrl), 
                headers: const {'ngrok-skip-browser-warning': 'true'},
                fit: BoxFit.cover, 
                errorBuilder: (_, __, ___) => const SizedBox()
              ),
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 18, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 6, color: Colors.black38)]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner['subtitle'] != null && banner['subtitle'].toString().isNotEmpty)
                    Text(
                      banner['subtitle'],
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Offer Card ────────────────────────────────────────────────────────────────
class _OfferCard extends StatelessWidget {
  final dynamic offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final imgUrl = offer['image_url'] as String?;
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image or Solid Color
            if (imgUrl != null && imgUrl.isNotEmpty)
              Image.network(
                ApiService.getImageUrl(imgUrl),
                headers: const {'ngrok-skip-browser-warning': 'true'},
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1F2937)),
              )
            else
              Container(color: const Color(0xFF1F2937)),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.1)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      offer['discount_text'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black45)]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (offer['description'] != null && offer['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      offer['description'],
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (offer['valid_until'] != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.timer_rounded, size: 13, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text('Until ${offer['valid_until']}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Popular Item Card ─────────────────────────────────────────────────────────
class _PopularCard extends StatelessWidget {
  final dynamic item;
  const _PopularCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 152,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(22)),
              child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                  ? Image.network(
                      ApiService.getImageUrl(item['image_url']), 
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                      fit: BoxFit.cover, 
                      errorBuilder: (_, __, ___) => _placeholder()
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('Rs ${item['price']}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
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
