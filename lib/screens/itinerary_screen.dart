import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/api_config.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/services/auth_service.dart';
import 'package:waygo_app/services/trip_service.dart';
import 'package:waygo_app/models/itinerary_model.dart';
import 'package:waygo_app/screens/ai_planner_screen.dart' show PlaceImageWidget;

class ItineraryScreen extends StatefulWidget {
  final ItineraryModel itinerary;
  const ItineraryScreen({super.key, required this.itinerary});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _authService = const AuthService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.itinerary.dayPlans.length, vsync: this);
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

      // We need to convert ItineraryModel to JSON list compatible with saveFullItinerary
      final dayPlansJson = widget.itinerary.dayPlans.map((d) => d.toJson()).toList();

      final success = await TripService().saveFullItinerary(
        userId: userId,
        name: widget.itinerary.location,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: widget.itinerary.days - 1)),
        dayPlans: dayPlansJson,
        token: token,
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Saved Successfully!'), backgroundColor: kTeal),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save trip. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error Saving Trip'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            _buildDaySelector(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.itinerary.dayPlans.map((day) => _DayTimelineView(day: day, location: widget.itinerary.location)).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kWhite.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_rounded, color: kWhite, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI GENERATED PLAN', style: TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                Text(widget.itinerary.location, style: const TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kWhite.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.share_rounded, color: kWhite, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicator: const BoxDecoration(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        tabs: widget.itinerary.dayPlans.asMap().entries.map((entry) {
          return Tab(
            child: AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) {
                final isSelected = _tabController.index == entry.key;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? kTeal : kWhite.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected ? [BoxShadow(color: kTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                  ),
                  child: Text(
                    'Day ${entry.key + 1}',
                    style: TextStyle(color: isSelected ? kWhite : kSlate, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [kNavy.withOpacity(0), kNavy], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveTrip,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: _isSaving ? LinearGradient(colors: [kTeal.withOpacity(0.5), kTeal.withOpacity(0.3)]) : kTealGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isSaving ? [] : [BoxShadow(color: kTeal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2.5))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bookmark_add_rounded, color: kWhite, size: 22), SizedBox(width: 12), Text('Save Entire Plan to My List', style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w700))]),
          ),
        ),
      ),
    );
  }
}

class _DayTimelineView extends StatelessWidget {
  final DayPlan day;
  final String location;
  const _DayTimelineView({required this.day, required this.location});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: day.activities.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
            child: Row(
              children: [
                Text('Day ${day.day}', style: const TextStyle(color: kWhite, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                Text(day.theme, style: const TextStyle(color: kTeal, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${day.activities.length} Places', style: const TextStyle(color: kSlate, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }
        final activity = day.activities[index - 1];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimelineRail(index - 1, day.activities.length),
              const SizedBox(width: 16),
              Expanded(child: _ActivityCard(activity: activity, cityName: location)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineRail(int index, int total) {
    return Column(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: kTeal, shape: BoxShape.circle, border: Border.all(color: kTeal.withOpacity(0.2), width: 3)),
        ),
        if (index != total - 1)
          Expanded(child: Container(width: 2, color: kWhite.withOpacity(0.1))),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final String cityName;
  const _ActivityCard({required this.activity, required this.cityName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(color: kNavy2, borderRadius: BorderRadius.circular(24), border: Border.all(color: kWhite.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: PlaceImageWidget(placeName: activity.name, cityName: cityName, category: activity.category, description: activity.description),
              ),
              Positioned(
                top: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle, border: Border.all(color: kWhite.withOpacity(0.2))),
                  child: const Icon(Icons.favorite_border_rounded, color: kWhite, size: 20),
                ),
              ),
              Positioned(
                bottom: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: kWhite.withOpacity(0.2))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${activity.rating}', style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: kWhite, size: 14),
                      const SizedBox(width: 6),
                      Text(activity.time, style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.name, style: const TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: kSlate, size: 14),
                    const SizedBox(width: 4),
                    Text(cityName, style: const TextStyle(color: kSlate, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(activity.description, style: TextStyle(color: kWhite.withOpacity(0.7), fontSize: 14, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Add to Itinerary', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: kWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(color: kWhite.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: kWhite.withOpacity(0.1))),
                      child: IconButton(onPressed: () {}, icon: const Icon(Icons.map_rounded, color: kTeal, size: 22)),
                    ),
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
