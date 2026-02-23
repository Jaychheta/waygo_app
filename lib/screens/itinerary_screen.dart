import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/config/api_config.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class TripPlace {
  final String time;
  final String placeName;
  final String description;

  const TripPlace({
    required this.time,
    required this.placeName,
    required this.description,
  });

  factory TripPlace.fromJson(Map<String, dynamic> json) => TripPlace(
        time: json['time']?.toString() ?? '',
        placeName: json['placeName']?.toString() ??
            json['place_name']?.toString() ??
            json['name']?.toString() ??
            '',
        description: json['description']?.toString() ?? '',
      );
}

class TripDay {
  final int day;
  final String? title;
  final List<TripPlace> places;

  const TripDay({
    required this.day,
    this.title,
    required this.places,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) => TripDay(
        day: (json['day'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? json['theme']?.toString(),
        places: (json['places'] as List<dynamic>? ??
                json['activities'] as List<dynamic>? ??
                [])
            .map((p) => TripPlace.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

// ─── API Helper ───────────────────────────────────────────────────────────────

Future<List<TripDay>> _fetchItinerary(String location, int days) async {
  final uri = Uri.parse(
    '${ApiConfig.baseUrl}/trips/generate-ai-plan'
    '?location=${Uri.encodeComponent(location)}&days=$days',
  );
  final response = await http.get(uri).timeout(ApiConfig.requestTimeout);
  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((d) => TripDay.fromJson(d as Map<String, dynamic>))
        .toList();
  }
  throw Exception('Server returned ${response.statusCode}');
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ItineraryScreen extends StatefulWidget {
  /// The destination that will be fetched from the AI plan API.
  final String location;

  /// Number of days for the trip.
  final int days;

  /// Optional override label shown in the app-bar (defaults to [location]).
  final String? tripName;

  const ItineraryScreen({
    super.key,
    required this.location,
    required this.days,
    this.tripName,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with TickerProviderStateMixin {
  late Future<List<TripDay>> _future;
  late TabController _tabController;
  int _tabCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _future = _fetchItinerary(widget.location, widget.days);
  }

  void _retry() {
    setState(() {
      _tabController.dispose();
      _tabController = TabController(length: 0, vsync: this);
      _tabCount = 0;
      _future = _fetchItinerary(widget.location, widget.days);
    });
  }

  void _onDaysLoaded(List<TripDay> days) {
    if (_tabCount == days.length) return;
    _tabController.dispose();
    _tabController = TabController(length: days.length, vsync: this);
    _tabCount = days.length;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: FutureBuilder<List<TripDay>>(
        future: _future,
        builder: (context, snapshot) {
          // ── Loading ────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          // ── Error ──────────────────────────────────────────────────────────
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildError(snapshot.error?.toString());
          }

          // ── Success ────────────────────────────────────────────────────────
          final tripDays = snapshot.data!;
          _onDaysLoaded(tripDays);

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [_buildSliverAppBar(tripDays)],
            body: Column(
              children: [
                _buildDayTabBar(tripDays),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: tripDays
                        .map((day) => _DayTimelineView(day: day))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Loading State ────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: kNavy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: kTeal.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: kTeal.withValues(alpha: 0.25), blurRadius: 30),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: kTeal, size: 42),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(
              color: kTeal,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'AI is planning your trip...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching the best places in ${widget.location}',
              style: const TextStyle(color: kSlate, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────────────────────

  Widget _buildError(String? message) {
    return Scaffold(
      backgroundColor: kNavy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: kNavy2,
                  shape: BoxShape.circle,
                  border: Border.all(color: kWhite.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.wifi_off_rounded, color: kSlate, size: 38),
              ),
              const SizedBox(height: 24),
              const Text(
                'Could not load plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kWhite),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection\nand try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kSlate, fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _retry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: kTealGradient,
                    borderRadius: BorderRadius.circular(kRadius12),
                    boxShadow: [
                      BoxShadow(color: kTeal.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: kWhite, size: 18),
                      SizedBox(width: 8),
                      Text('Retry', style: TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSlate.withValues(alpha: 0.5), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar(List<TripDay> days) {
    final totalPlaces = days.fold(0, (s, d) => s + d.places.length);
    return SliverAppBar(
      backgroundColor: kNavy,
      expandedHeight: 140,
      pinned: true,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kNavy2,
            shape: BoxShape.circle,
            border: Border.all(color: kWhite.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kWhite),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kNavy2,
              shape: BoxShape.circle,
              border: Border.all(color: kWhite.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.share_rounded, size: 18, color: kWhite),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tripName ?? widget.location,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kWhite,
              ),
            ),
            Text(
              '${days.length} days · $totalPlaces places',
              style: const TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF081528), kNavy],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Opacity(
              opacity: 0.06,
              child: Icon(Icons.map_rounded, size: 200, color: kTeal),
            ),
          ),
        ),
      ),
    );
  }

  // ── Day Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildDayTabBar(List<TripDay> days) {
    return Container(
      color: kNavy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.zero,
        tabs: days.asMap().entries.map((entry) {
          return _DayTab(
            index: entry.key,
            day: entry.value,
            controller: _tabController,
          );
        }).toList(),
      ),
    );
  }
}

// ─── Animated Day Tab ────────────────────────────────────────────────────────

class _DayTab extends StatefulWidget {
  final int index;
  final TripDay day;
  final TabController controller;

  const _DayTab({required this.index, required this.day, required this.controller});

  @override
  State<_DayTab> createState() => _DayTabState();
}

class _DayTabState extends State<_DayTab> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.controller.index == widget.index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 8, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? kTeal : kNavy2,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isSelected ? kTeal : kWhite.withValues(alpha: 0.08),
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: kTeal.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: Text(
        'Day ${widget.day.day}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected ? kNavy : kSlate,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Day Timeline View ───────────────────────────────────────────────────────

class _DayTimelineView extends StatelessWidget {
  final TripDay day;
  const _DayTimelineView({required this.day});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: day.places.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) return _buildDayHeader();
        final placeIndex = index - 1;
        return _TimelinePlaceCard(
          place: day.places[placeIndex],
          isFirst: placeIndex == 0,
          isLast: placeIndex == day.places.length - 1,
          index: placeIndex,
        );
      },
    );
  }

  Widget _buildDayHeader() {
    if (day.title == null || day.title!.isEmpty) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: kTealGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kTeal.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: kWhite, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAY ${day.day}',
                  style: const TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
                Text(
                  day.title!,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kWhite),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kTeal.withValues(alpha: 0.25)),
            ),
            child: Text(
              '${day.places.length} stops',
              style: const TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Timeline Place Card ──────────────────────────────────────────────────────

class _TimelinePlaceCard extends StatefulWidget {
  final TripPlace place;
  final bool isFirst;
  final bool isLast;
  final int index;

  const _TimelinePlaceCard({
    required this.place,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  @override
  State<_TimelinePlaceCard> createState() => _TimelinePlaceCardState();
}

class _TimelinePlaceCardState extends State<_TimelinePlaceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 80),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 90), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimelineRail(),
              const SizedBox(width: 14),
              Expanded(child: _buildCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineRail() {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          if (!widget.isFirst)
            Container(width: 2, height: 14, color: kTeal.withValues(alpha: 0.35))
          else
            const SizedBox(height: 14),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kTeal.withValues(alpha: 0.15),
              border: Border.all(color: kTeal, width: 2),
              boxShadow: [BoxShadow(color: kTeal.withValues(alpha: 0.4), blurRadius: 10)],
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
              ),
            ),
          ),
          if (!widget.isLast)
            Expanded(
              child: Container(
                width: 2,
                color: kTeal.withValues(alpha: 0.35),
                margin: const EdgeInsets.only(top: 4),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kNavy2,
          borderRadius: BorderRadius.circular(kRadius16),
          border: Border.all(
            color: _expanded ? kTeal.withValues(alpha: 0.4) : kWhite.withValues(alpha: 0.06),
          ),
          boxShadow: _expanded
              ? [BoxShadow(color: kTeal.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kTeal.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 11, color: kTeal),
                        const SizedBox(width: 4),
                        Text(
                          widget.place.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kTeal,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: kSlate, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.place_rounded, size: 16, color: kTeal),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.place.placeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFF1E3A5A), height: 1),
                    const SizedBox(height: 10),
                    Text(
                      widget.place.description,
                      style: const TextStyle(fontSize: 13, color: kSlate, height: 1.55),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _actionChip(Icons.directions_rounded, 'Directions'),
                        const SizedBox(width: 8),
                        _actionChip(Icons.bookmark_outline_rounded, 'Save'),
                      ],
                    ),
                  ],
                ),
              ),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: Text(
                  widget.place.description,
                  style: const TextStyle(fontSize: 12.5, color: kSlate, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kNavy3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWhite.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kTeal),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: kSlate, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
