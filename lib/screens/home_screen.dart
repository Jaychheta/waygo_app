import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/create_trip_screen.dart';
import 'package:waygo_app/screens/itinerary_screen.dart';
import 'package:waygo_app/services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userName});
  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tripService = const TripService();
  List<dynamic> _trips = [];
  bool _loading = true;

  // Static recommendations
  final _recommendations = [
    {'name': 'Ha Long Bay, Vietnam', 'desc': 'Experience the emerald waters and thousands of towering limestone...', 'rating': '4.9', 'reviews': '1.2k', 'color': 0xFF1565C0},
    {'name': 'Venice, Italy', 'desc': 'Explore the historic canals and romantic architecture of the floating...', 'rating': '4.8', 'reviews': '3.4k', 'color': 0xFF6A1B9A},
    {'name': 'Santorini, Greece', 'desc': 'Iconic white-washed buildings with blue domes overlooking the Aegean...', 'rating': '4.9', 'reviews': '5.1k', 'color': 0xFF0277BD},
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final trips = await _tripService.getUserTrips(1);
    if (mounted) setState(() { _trips = trips; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      color: kTeal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 28),
          _buildActiveTrips(),
          const SizedBox(height: 28),
          _buildQuickActions(context),
          const SizedBox(height: 28),
          _buildRecommendedSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: kTealGradient,
            border: Border.all(color: kTeal.withValues(alpha: 0.5), width: 2),
          ),
          child: const Icon(Icons.person_rounded, color: kWhite, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,', style: TextStyle(color: kSlate, fontSize: 13)),
              Text(
                'Hello, ${widget.userName}! 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWhite),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: kNavy2,
                shape: BoxShape.circle,
                border: Border.all(color: kWhite.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.notifications_outlined, color: kWhite, size: 22),
            ),
            Positioned(
              right: 8, top: 8,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveTrips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Active Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
            Text('See All', style: TextStyle(color: kTeal, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: kTeal)))
        else if (_trips.isEmpty)
          _emptyTrips()
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trips.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ItineraryScreen(
                      location: _trips[i]['location']?.toString() ?? _trips[i]['name']?.toString() ?? 'India',
                      days: (_trips[i]['days'] as num?)?.toInt() ?? 3,
                      tripName: _trips[i]['name']?.toString() ?? 'My Trip',
                    ),
                  ),
                ),
                child: _tripCard(_trips[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyTrips() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kWhite.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 40, color: kSlate.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          const Text('No active trips yet', style: TextStyle(color: kSlate, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _tripCard(Map<String, dynamic> trip) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius),
        gradient: LinearGradient(
          colors: [kNavy3, kNavy2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: kWhite.withValues(alpha: 0.07)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kNavy.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
              child: const Text('Upcoming', style: TextStyle(color: kTeal, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.flight_takeoff_rounded, color: kTeal, size: 28),
                const Spacer(),
                Text(trip['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: kSlate, size: 12),
                    const SizedBox(width: 4),
                    Text(trip['location'] ?? 'India', style: const TextStyle(color: kSlate, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 4,
                    backgroundColor: kNavy3,
                    valueColor: const AlwaysStoppedAnimation<Color>(kTeal),
                  ),
                ),
                const SizedBox(height: 6),
                const Text('PRE-TRIP CHECKLIST  65%', style: TextStyle(color: kSlate, fontSize: 10, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'New Journey', 'icon': Icons.add_circle_outline_rounded, 'color': 0xFF14B8A6},
      {'label': 'View Map', 'icon': Icons.map_outlined, 'color': 0xFF3B82F6},
      {'label': 'Saved Places', 'icon': Icons.bookmark_outline_rounded, 'color': 0xFF8B5CF6},
      {'label': 'Travel Wallet', 'icon': Icons.wallet_rounded, 'color': 0xFFEA580C},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: actions.map((a) {
            final color = Color(a['color'] as int);
            return GestureDetector(
              onTap: a['label'] == 'New Journey'
                  ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CreateTripScreen()))
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: kNavy2,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kWhite.withValues(alpha: 0.06)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(a['icon'] as IconData, color: color, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(a['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kWhite)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
        const SizedBox(height: 14),
        ..._recommendations.map((r) => _recommendCard(r)),
      ],
    );
  }

  Widget _recommendCard(Map<String, dynamic> r) {
    final color = Color(r['color'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kWhite.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.landscape_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kWhite)),
                const SizedBox(height: 4),
                Text(r['desc'] as String, style: const TextStyle(fontSize: 12, color: kSlate), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 3),
                    Text('${r['rating']} (${r['reviews']} reviews)', style: const TextStyle(fontSize: 11, color: kSlate)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
