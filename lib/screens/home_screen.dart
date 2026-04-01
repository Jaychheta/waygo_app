import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../config/app_theme.dart';
import 'create_trip_screen.dart';
import 'saved_trip_details_screen.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../models/trip_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/shimmer_loader.dart';
import '../widgets/animated_card.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';
import 'explore_screen.dart';
import 'saved_trips_screen.dart';
import 'insights_screen.dart';

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
  Future<List<TripModel>>? _tripsFuture;
  Timer? _refreshTimer;
  bool _isInit = false;

  String get _initials {
    if (widget.userName.isEmpty) return 'TR';
    final parts = widget.userName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _tripsFuture = _fetchTrips();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadTrips(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadTrips();
    }
    _isInit = true;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String resolveImageUrl(String? dbImageUrl, String destinationName) {
    if (dbImageUrl != null && dbImageUrl.isNotEmpty) {
      if (dbImageUrl.startsWith('http')) return dbImageUrl;
      return ApiConfig.baseUrl + dbImageUrl;
    }
    final encoded = Uri.encodeComponent(destinationName.toLowerCase());
    return 'https://source.unsplash.com/800x600/?$encoded,travel';
  }

  Future<List<TripModel>> _fetchTrips() async {
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) return [];
    final userId = int.tryParse(userIdStr) ?? 0;
    final token = await _authService.getToken();
    return const TripService().getUserTrips(userId, token: token);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kSurface,
      body: RefreshIndicator(
        color: const Color(0xFF00BFA5),
        backgroundColor: const Color(0xFF111111),
        onRefresh: () async {
          await _loadTrips();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 1. Luxury App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: kSurface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: const Text(
                'Discover',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _buildAvatar(),
              ).animate().fadeIn(delay: 400.ms).scale(curve: Curves.easeOutBack),
            ],
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Where will your curiosity take you today?',
                    style: TextStyle(
                      color: kWhite.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),
                  
                  // Active Trips Section
                  _sectionHeader('Active Journeys', 'View all'),
                  const SizedBox(height: 16),
                  _buildTripsCarousel(),

                  const SizedBox(height: 40),

                  // Quick Actions Grid
                  _sectionHeader('Quick Actions', null),
                  const SizedBox(height: 20),
                  _buildStaggeredActions(),

                  const SizedBox(height: 120), // Bottom nav padding
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kTeal.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kTeal.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            color: kTeal,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kWhite,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (action != null)
          Text(
            action,
            style: const TextStyle(
              color: kTeal,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildTripsCarousel() {
    return SizedBox(
      height: 280,
      child: FutureBuilder<List<TripModel>>(
        future: _tripsFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, index) => const ShimmerTripCard(),
            );
          }
          final trips = snapshot.data ?? [];
          if (trips.isEmpty) return _buildEmptyTrips();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: trips.length,
            padding: EdgeInsets.zero,
            itemBuilder: (ctx, i) => AnimatedCard(
              index: i,
              child: _tripCard(trips[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _tripCard(TripModel trip) {
    final name = trip.name;
    final location = trip.location;
    final startDate = trip.startDate.toIso8601String().substring(5, 10);
    final endDate = trip.endDate.toIso8601String().substring(5, 10);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavedTripDetailsScreen(
            tripId: trip.id,
            tripName: name,
          ),
        ),
      ),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Image
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: resolveImageUrl(trip.imageUrl, location),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00BFA5),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFF1A1A2E),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.landscape_outlined,
                          color: Colors.white24, size: 40),
                        const SizedBox(height: 8),
                        Text(location,
                          style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: kTeal, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          '$startDate - $endDate',
                          style: TextStyle(
                            color: kWhite.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: kWhite.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6, // Mock progress
                            child: Container(
                              decoration: BoxDecoration(
                                color: kTeal,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(color: kTeal.withValues(alpha: 0.4), blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(flex: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Top Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Text(
                    'ONGOING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaggeredActions() {
    final actions = [
      {'icon': Icons.add_rounded, 'label': 'New Trip', 'color': kTeal, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTripScreen()))},
      {'icon': Icons.map_rounded, 'label': 'Explore', 'color': Colors.blueAccent, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()))},
      {'icon': Icons.bookmark_rounded, 'label': 'Saved', 'color': Colors.amber, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedTripsScreen()))},
      {'icon': Icons.insights_rounded, 'label': 'Insights', 'color': Colors.purpleAccent, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InsightsScreen()))},
    ];

    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action['onTap'] as VoidCallback,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (20 * index).ms).scale(delay: (20 * index).ms);
      },
    );
  }

  Widget _buildEmptyTrips() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_outlined, color: kTeal, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No Active Journeys',
            style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Your upcoming adventures will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kWhite.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
