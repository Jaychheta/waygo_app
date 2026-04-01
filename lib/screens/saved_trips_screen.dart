import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/trip_model.dart';
import '../services/trip_service.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_card.dart';
import 'saved_trip_details_screen.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  final _tripService = const TripService();
  final _authService = const AuthService();
  List<TripModel>? _trips;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllTrips();
  }

  Future<void> _loadAllTrips() async {
    final token = await _authService.getToken();
    final userIdStr = await _authService.getUserId();
    if (userIdStr != null) {
      final userId = int.parse(userIdStr);
      final trips = await _tripService.getUserTrips(userId, token: token);
      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('SAVED EXPEDITIONS', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: kTeal))
        : _trips == null || _trips!.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _trips!.length,
              itemBuilder: (ctx, i) => AnimatedCard(
                index: i,
                child: _buildTripItem(_trips![i]),
              ),
            ),
    );
  }

  Widget _buildTripItem(TripModel trip) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavedTripDetailsScreen(tripId: trip.id, tripName: trip.name),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: kTeal.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.beach_access_rounded, color: kTeal, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(trip.location, style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.startDate.day}/${trip.startDate.month} - ${trip.endDate.day}/${trip.endDate.month}',
                      style: const TextStyle(color: kTeal, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: kWhite, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded, color: kWhite.withValues(alpha: 0.1), size: 100),
          const SizedBox(height: 20),
          const Text('No Saved Journeys', style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('You haven\'t saved any expeditions yet.', style: TextStyle(color: kWhite.withValues(alpha: 0.3))),
        ],
      ),
    );
  }
}
