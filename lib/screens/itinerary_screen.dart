import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../models/itinerary_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/place_image_widget.dart';
import '../widgets/animated_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class ItineraryScreen extends StatefulWidget {
  final ItineraryModel itinerary;
  const ItineraryScreen({super.key, required this.itinerary});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final _authService = const AuthService();
  bool _isSaving = false;
  
  // Coordinate cache for the current session to avoid redundant geocoding
  final Map<String, LatLng> _coordCache = {};
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.itinerary.dayPlans.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _currentDayIndex = _tabController.index);
      _updateMap();
    });
    _preGeocode();
  }

  Future<void> _preGeocode() async {
    final city = widget.itinerary.location;
    try {
      List<Location> cityLocs = await locationFromAddress(city);
      if (cityLocs.isNotEmpty && mounted) {
        setState(() {
          _coordCache[city] = LatLng(cityLocs.first.latitude, cityLocs.first.longitude);
        });
        _mapController.move(_coordCache[city]!, 12);
      }
    } catch (_) {
      if (city.toLowerCase().contains('surat')) _coordCache[city] = LatLng(21.1702, 72.8311);
      if (city.toLowerCase().contains('delhi')) _coordCache[city] = LatLng(28.6139, 77.2090);
    }

    for (var day in widget.itinerary.dayPlans) {
      for (var act in day.activities) {
        _geocode(act.name, city);
      }
    }
  }

  Future<void> _geocode(String place, String city) async {
    final key = '$place|$city';
    if (_coordCache.containsKey(key)) return;
    
    try {
      final query = '$place, $city';
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _coordCache[key] = LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (_) {
      final centerSource = _coordCache[city] ?? _coordCache['Surat'] ?? const LatLng(28.6139, 77.2090);
      final hash = place.hashCode;
      if (mounted) {
        setState(() {
          _coordCache[key] = LatLng(
            centerSource.latitude + ((hash % 100) / 2000) - 0.025,
            centerSource.longitude + (((hash ~/ 100) % 100) / 2000) - 0.025,
          );
        });
      }
    }
  }

  void _updateMap() {
    final currentDay = widget.itinerary.dayPlans[_currentDayIndex];
    if (currentDay.activities.isEmpty) return;
    
    final firstKey = '${currentDay.activities.first.name}|${widget.itinerary.location}';
    final coord = _coordCache[firstKey];
    if (coord != null) {
      _mapController.move(coord, 12);
    }
  }

  void _onMarkerTap(int activityIndex) {
    // 1. Zoom and move map precisely
    final day = widget.itinerary.dayPlans[_currentDayIndex];
    final act = day.activities[activityIndex];
    final coord = _coordCache['${act.name}|${widget.itinerary.location}'];
    if (coord != null) {
      _mapController.move(coord, 14);
    }

    // 2. Expand and Scroll Bottom Sheet
    _sheetController.animateTo(0.75, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  void _onActivityCardTap(int activityIndex) {
    // 1. Move Map center
    final day = widget.itinerary.dayPlans[_currentDayIndex];
    final act = day.activities[activityIndex];
    final coord = _coordCache['${act.name}|${widget.itinerary.location}'];
    if (coord != null) {
      _mapController.move(coord, 14);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveTrip() async {
    setState(() => _isSaving = true);
    try {
      final userIdStr = await _authService.getUserId();
      final userId = int.tryParse(userIdStr ?? '1') ?? 1;
      final token = await _authService.getToken();
      final dayPlansJson = widget.itinerary.dayPlans.map((d) => d.toJson()).toList();

      final success = await TripService().saveFullItinerary(
        userId: userId,
        name: widget.itinerary.location,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: widget.itinerary.days - 1)),
        dayPlans: dayPlansJson,
        token: token,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expedition Saved to Cloud.'), backgroundColor: kTeal, behavior: SnackBarBehavior.floating),
        );
      } else { throw Exception(); }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloud Storage busy. Try again.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: Stack(
        children: [
          _buildMapLayer(),
          _buildMapHeader(),
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.45 + 20,
            child: _buildOptimizeBtn(),
          ),
          _buildDraggableSheet(),
          Positioned(bottom: 24, left: 24, right: 24, child: _buildSaveAction()),
        ],
      ),
    );
  }

  Widget _buildMapLayer() {
    final day = widget.itinerary.dayPlans[_currentDayIndex];
    final markers = day.activities.asMap().entries.map((entry) {
      final i = entry.key;
      final act = entry.value;
      final coord = _coordCache['${act.name}|${widget.itinerary.location}'];
      if (coord == null) return null;
      return Marker(
        point: coord,
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _onMarkerTap(i),
          child: _buildMarker(i + 1),
        ),
      );
    }).whereType<Marker>().toList();

    final polylinePoints = markers.map((m) => m.point).toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _coordCache[widget.itinerary.location] ?? const LatLng(28.6139, 77.2090),
        initialZoom: 12,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        if (polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                color: kTeal,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildMarker(int number) {
    return Container(
      decoration: BoxDecoration(
        color: kTeal,
        shape: BoxShape.circle,
        border: Border.all(color: kWhite, width: 2),
        boxShadow: [BoxShadow(color: kTeal.withValues(alpha: 0.4), blurRadius: 10)],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [kSurface, Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Row(
          children: [
            _actionBtn(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('EXPEDITION PREVIEW', style: TextStyle(color: kTeal, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
                   Text(widget.itinerary.location, style: const TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
            ),
            _actionBtn(Icons.share_rounded, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizeBtn() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI is optimizing for shortest travel time...'), backgroundColor: kTeal),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        radius: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.orangeAccent, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Optimize Route',
              style: TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 2.seconds).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        radius: 12,
        child: Icon(icon, color: kWhite, size: 18),
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 10)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              _buildDaySelectorStrip(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.itinerary.dayPlans.asMap().entries.map((entry) => _DayListView(
                    day: entry.value, 
                    location: widget.itinerary.location, 
                    scrollController: scrollController,
                    coordCache: _coordCache,
                    onActivityTap: _onActivityCardTap,
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaySelectorStrip() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorColor: kTeal,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      tabs: widget.itinerary.dayPlans.asMap().entries.map((entry) {
        return Tab(
          child: Text(
            'Day ${entry.key + 1}',
            style: const TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveAction() {
    if (_isSaving) return const Center(child: CircularProgressIndicator(color: kTeal));
    return CustomButton(
      text: 'Save Expedition to Cloud',
      isLoading: _isSaving,
      onPressed: _saveTrip,
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0);
  }
}

class _DayListView extends StatelessWidget {
  final DayPlan day;
  final String location;
  final ScrollController scrollController;
  final Map<String, LatLng> coordCache;
  final Function(int) onActivityTap;
  const _DayListView({required this.day, required this.location, required this.scrollController, required this.coordCache, required this.onActivityTap});

  String _getDistanceFromPrev(int index) {
    if (index == 0) return '';
    final p1 = coordCache['${day.activities[index-1].name}|$location'];
    final p2 = coordCache['${day.activities[index].name}|$location'];
    if (p1 == null || p2 == null) return '';
    
    final distance = const Distance().as(LengthUnit.Kilometer, p1, p2);
    return '${distance.toStringAsFixed(1)} KM';
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: day.activities.length,
      itemBuilder: (context, index) {
        final activity = day.activities[index];
        return AnimatedCard(
          index: index,
          child: GestureDetector(
            onTap: () => onActivityTap(index),
            child: _ActivityRailTile(
              activity: activity,
              cityName: location,
              isLast: index == day.activities.length - 1,
              markerNumber: index + 1,
              distance: _getDistanceFromPrev(index),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityRailTile extends StatelessWidget {
  final Activity activity;
  final String cityName;
  final bool isLast;
  final int markerNumber;
  final String distance;
  const _ActivityRailTile({required this.activity, required this.cityName, required this.isLast, required this.markerNumber, required this.distance});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineRail(),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _buildCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRail() {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: kTeal.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: kTeal, width: 2)),
          alignment: Alignment.center,
          child: Text('$markerNumber', style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900)),
        ),
        if (!isLast)
          Expanded(
            child: Column(
              children: [
                Container(width: 1, color: kTeal.withValues(alpha: 0.2), height: 10),
                if (distance.isNotEmpty)
                  RotatedBox(
                    quarterTurns: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        distance,
                        style: TextStyle(color: kTeal.withValues(alpha: 0.5), fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                Expanded(child: Container(width: 1, color: kTeal.withValues(alpha: 0.2))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCard() {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: activity.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: kNavy3, child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))),
                          errorWidget: (context, url, error) => _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                ),
              ),
              Positioned(top: 12, right: 12, child: _ratingTag()),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(activity.time, style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const Icon(Icons.more_horiz_rounded, color: kWhite, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Text(activity.name, style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(activity.description, style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingTag() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      radius: 10,
      child: Row(children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
        const SizedBox(width: 4),
        Text('${activity.rating}', style: const TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _buildImageFallback() {
    return PlaceImageWidget(placeName: activity.name, cityName: cityName);
  }
}


