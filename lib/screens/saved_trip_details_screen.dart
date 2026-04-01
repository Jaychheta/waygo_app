import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../services/trip_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_card.dart';
import '../widgets/custom_button.dart';

class SavedTripDetailsScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  const SavedTripDetailsScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<SavedTripDetailsScreen> createState() => _SavedTripDetailsScreenState();
}

class _SavedTripDetailsScreenState extends State<SavedTripDetailsScreen> {
  final _tripService = const TripService();
  late Future<List<dynamic>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = _tripService.getTripPlaces(widget.tripId);
  }

  void _showAddPlaceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPlaceSheet(
        tripId: widget.tripId,
        onAdded: () {
          setState(() {
            _placesFuture = _tripService.getTripPlaces(widget.tripId);
          });
        },
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _placesFuture = _tripService.getTripPlaces(widget.tripId);
    });
    await _placesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: kTeal,
        backgroundColor: kSurface2,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                child: Row(
                  children: [
                    const Text(
                      'JOURNEY LOG',
                      style: TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ).animate().fadeIn(),
                    const Spacer(),
                    const Icon(Icons.sort_rounded, color: kWhite, size: 16),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: _placesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: kTeal))),
                  );
                }
                final places = snapshot.data ?? [];
                if (places.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => AnimatedCard(
                        index: i,
                        child: _placeTimelineTile(places[i], i == places.length - 1),
                      ),
                      childCount: places.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlaceSheet,
        backgroundColor: kTeal,
        child: const Icon(Icons.add_location_alt_rounded, color: kWhite, size: 28),
      ).animate().scale(delay: 500.ms),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: kSurface,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          widget.tripName,
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -1),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [kTeal.withValues(alpha: 0.1), kSurface], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            Positioned(
              top: 60,
              right: 20,
              child: const Icon(Icons.map_rounded, color: kTeal, size: 140).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeTimelineTile(dynamic place, bool isLast) {
    final name = place['name'] ?? 'Expedition Point';
    final time = place['time'] ?? 'Planned';
    final location = place['location'] ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineRail(isLast),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w800))),
                        Text(time, style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: kTeal, size: 12),
                          const SizedBox(width: 6),
                          Text(location, style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRail(bool isLast) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 24),
          decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
        ).animate().scale(duration: 400.ms),
        if (!isLast)
          Expanded(
            child: Container(
              width: 1,
              color: kWhite.withValues(alpha: 0.1),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.explore_off_rounded, color: kWhite.withValues(alpha: 0.05), size: 120),
          const SizedBox(height: 20),
          Text('No waypoints charted.', style: TextStyle(color: kWhite.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

class _AddPlaceSheet extends StatefulWidget {
  final int tripId;
  final VoidCallback onAdded;
  const _AddPlaceSheet({required this.tripId, required this.onAdded});

  @override
  State<_AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<_AddPlaceSheet> {
  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _tripService = const TripService();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: GlassContainer(
        radius: 32,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Landmark', style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 32),
            _sheetField('Point Name', _nameCtrl, Icons.place_rounded),
            const SizedBox(height: 20),
            _sheetField('Timestamp', _timeCtrl, Icons.access_time_filled_rounded),
            const SizedBox(height: 48),
            CustomButton(text: 'Anchor to Itinerary', isLoading: _isSubmitting, onPressed: _submit),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kTeal, size: 18),
            filled: true,
            fillColor: kWhite.withValues(alpha: 0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kTeal)),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    
    try {
      final placeData = {
        'name': _nameCtrl.text.trim(), 
        'location': 'Journey Point', 
        'time': _timeCtrl.text.trim(), 
        'description': 'Added manually via Journey Log', 
        'rating': 5.0, 
        'isPopular': false
      };

      final result = await _tripService.addPlace(widget.tripId, placeData);
      
      if (result && mounted) {
        Navigator.pop(context); // Close sheet immediately on success
        widget.onAdded(); // Then refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add landmark. Please check your connection.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
