import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/api_config.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/create_trip_screen.dart';
import 'package:waygo_app/screens/saved_trip_details_screen.dart';
import 'package:waygo_app/services/auth_service.dart';
import 'package:waygo_app/services/trip_service.dart';
import 'package:waygo_app/screens/ai_planner_screen.dart' show PlaceImageWidget;

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = 'Traveler'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _authService = const AuthService();
  Future<List<dynamic>>? _tripsFuture;

  String get _initials {
    if (widget.userName.isEmpty) return 'TR';
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _tripsFuture = _fetchTrips();
  }

  Future<List<dynamic>> _fetchTrips() async {
    final userIdStr = await _authService.getUserId() ?? '1';
    final userId = int.tryParse(userIdStr) ?? 1;
    final token = await _authService.getToken();
    
    return TripService().getUserTrips(userId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: RefreshIndicator(
          color: kTeal,
          onRefresh: () async => setState(() => _tripsFuture = _fetchTrips()),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildActiveTripsSection(),
              const SizedBox(height: 40),
              _buildQuickActionsGrid(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: kTealGradient,
            boxShadow: [
              BoxShadow(
                color: kTeal.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: kNavy,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: kNavy3,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: kWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(color: kSlate, fontSize: 13, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Text('Hello, ${widget.userName.split(' ')[0]}!', style: const TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: kWhite.withOpacity(0.05), shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded, color: kWhite, size: 24),
        ),
      ],
    );
  }

  Widget _buildActiveTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Active Trips', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () {},
              child: const Text('See All', style: TextStyle(color: kTeal, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: FutureBuilder<List<dynamic>>(
            future: _tripsFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: kTeal));
              }
              final trips = snapshot.data ?? [];
              if (trips.isEmpty) return _emptyTripsCard();
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: trips.length,
                itemBuilder: (ctx, i) => _tripCard(trips[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tripCard(Map<String, dynamic> trip) {
    final name = trip['name']?.toString() ?? 'Unknown Trip';
    final location = trip['location']?.toString() ?? 'Somewhere';
    final dates = trip['start_date'] != null ? '${trip['start_date'].toString().substring(5, 10)} - ${trip['end_date'].toString().substring(5, 10)}' : 'No dates';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SavedTripDetailsScreen(tripId: (trip['id'] as num).toInt(), tripName: name))),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 20, bottom: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]),
        child: Stack(
          children: [
             ClipRRect(
               borderRadius: BorderRadius.circular(28),
               child: PlaceImageWidget(placeName: location, cityName: location),
             ),
             // Gradient Overlay for readability
             Container(
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(28),
                 gradient: LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
               ),
             ),
             Positioned(
               top: 16, right: 16,
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                 decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12), border: Border.all(color: kWhite.withOpacity(0.1))),
                 child: const Text('In 5 days', style: TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w700)),
               ),
             ),
             Positioned(
               bottom: 12, left: 12, right: 12,
               child: Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(color: kWhite.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: kWhite.withOpacity(0.1))),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(name, style: const TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                               const SizedBox(height: 4),
                               Row(
                                 children: [
                                   const Icon(Icons.calendar_today_rounded, color: kTeal, size: 12),
                                   const SizedBox(width: 6),
                                   Text(dates, style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         Container(
                           width: 32, height: 32,
                           decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
                           child: const Icon(Icons.keyboard_arrow_right_rounded, color: kWhite, size: 20),
                         ),
                       ],
                     ),
                     const SizedBox(height: 14),
                     Stack(
                       children: [
                         Container(height: 4, decoration: BoxDecoration(color: kWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
                         Container(width: 80, height: 4, decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(2))),
                       ],
                     ),
                     const SizedBox(height: 8),
                     const Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('PRE-TRIP CHECKLIST', style: TextStyle(color: kWhite, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
                         Text('75%', style: TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w600)),
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

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _quickActionCard(Icons.add_circle_outline_rounded, 'New Journey', () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CreateTripScreen()))),
            _quickActionCard(Icons.map_rounded, 'View Map', () {}),
            _quickActionCard(Icons.bookmark_rounded, 'Saved Places', () {}),
            _quickActionCard(Icons.wallet_rounded, 'Travel Wallet', () {}),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: kNavy2, borderRadius: BorderRadius.circular(24), border: Border.all(color: kWhite.withOpacity(0.05))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kWhite.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(icon, color: kTeal, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recommendations = [
      {'title': 'Ha Long Bay, Vietnam', 'desc': 'Experience emerald waters and towering limestone cliffs.', 'rating': '4.9', 'img': 'Vietnam'},
      {'title': 'Venice, Italy', 'desc': 'Explore historic canals and romantic architecture.', 'rating': '4.8', 'img': 'Italy'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recommended for You', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        ...recommendations.map((r) => _recommendationCard(r)).toList(),
      ],
    );
  }

  Widget _recommendationCard(Map<String, String> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kNavy2, borderRadius: BorderRadius.circular(24), border: Border.all(color: kWhite.withOpacity(0.05))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 80, height: 80, child: PlaceImageWidget(placeName: r['img']!, cityName: r['img']!)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title']!, style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(r['desc']!, style: TextStyle(color: kSlate, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(r['rating']!, style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('(1.2k reviews)', style: TextStyle(color: kSlate, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTripsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: kNavy2, borderRadius: BorderRadius.circular(24), border: Border.all(color: kWhite.withOpacity(0.05))),
      child: Column(
        children: [
          const Icon(Icons.explore_outlined, color: kTeal, size: 48),
          const SizedBox(height: 16),
          const Text('No Active Trips', style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Your planned adventures will appear here.', textAlign: TextAlign.center, style: TextStyle(color: kSlate)),
        ],
      ),
    );
  }
}
