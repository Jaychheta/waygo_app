import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/api_config.dart';
import 'package:waygo_app/config/app_theme.dart';

/// Safely parses a value that may be a [num] or a [String] to [double].
double? _safeParseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

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
  late Future<List<dynamic>> _placesFuture;

  // ── Manual add dialog controllers ────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _placesFuture = _fetchPlaces();
  }

  Future<List<dynamic>> _fetchPlaces() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/trips/trip/${widget.tripId}/places'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as List<dynamic>;
      }
    } catch (_) {}
    return [];
  }

  // ── Manual place add ─────────────────────────────────────────────────────
  Future<void> _addCustomPlace() async {
    _nameCtrl.clear();
    _timeCtrl.clear();

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF0D1F38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: kTeal.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kTeal.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_location_alt_rounded, color: kTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Add a Place / Note',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Place Name field ─────────────────────────────────
                  const Text('Place Name / Note *',
                      style: TextStyle(fontSize: 12, color: kTeal, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: kTeal,
                    decoration: InputDecoration(
                      hintText: 'e.g. Visit Gateway of India',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF172A46),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kTeal.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kTeal.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kTeal, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Time field ───────────────────────────────────────
                  const Text('Time / Detail (Optional)',
                      style: TextStyle(fontSize: 12, color: kTeal, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _timeCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: kTeal,
                    decoration: InputDecoration(
                      hintText: 'e.g. 10:00 AM',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF172A46),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kTeal.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kTeal.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kTeal, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Buttons ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: saving ? null : () => Navigator.pop(dialogCtx),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.15),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final name = _nameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a place name.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  setDialogState(() => saving = true);
                                  try {
                                    final body = jsonEncode({
                                      'trip_id': widget.tripId,
                                      'place_data': {
                                        'name': name,
                                        'location': 'Custom Entry',
                                        'time': _timeCtrl.text.trim(),
                                        'description': 'Manually added reminder',
                                        'rating': 5.0,
                                        'isPopular': false,
                                      },
                                    });
                                    final res = await http.post(
                                      Uri.parse('${ApiConfig.baseUrl}/trips/add-place'),
                                      headers: {'Content-Type': 'application/json'},
                                      body: body,
                                    ).timeout(const Duration(seconds: 10));

                                    if (!dialogCtx.mounted) return;
                                    Navigator.pop(dialogCtx);

                                    if (res.statusCode == 200) {
                                      setState(() => _placesFuture = _fetchPlaces());
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(
                                          content: Text('"$name" added to your trip! ✓'),
                                          backgroundColor: kTeal,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to save. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    if (!dialogCtx.mounted) return;
                                    Navigator.pop(dialogCtx);
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Network error. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F38),
      floatingActionButton: FloatingActionButton(
        heroTag: 'saved_trip_details_fab',
        onPressed: _addCustomPlace,
        backgroundColor: const Color(0xFF14B8A6),
        elevation: 6,
        tooltip: 'Add place / note',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0D1F38),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _placesFuture = _fetchPlaces()),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: kTeal, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Text(
                widget.tripName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF172A46), Color(0xFF0D1F38)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // decorative teal arc
                  Positioned(
                    top: -60, right: -60,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kTeal.withOpacity(0.15),
                      ),
                    ),
                  ),
                  // icon + label in center
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kTeal.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Trip #${widget.tripId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.15),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // bottom fade
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, const Color(0xFF0D1F38).withOpacity(0.15)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // section heading
                  Row(
                    children: [
                      Container(
                        width: 4, height: 20,
                        decoration: BoxDecoration(
                          color: kTeal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Saved Places',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── FutureBuilder ────────────────────────────────────────
                  FutureBuilder<List<dynamic>>(
                    future: _placesFuture,
                    builder: (context, snapshot) {
                      // Loading
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF14B8A6), strokeWidth: 3,
                            ),
                          ),
                        );
                      }

                      // Empty
                      final places = snapshot.data ?? [];
                      if (places.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF172A46),
                            borderRadius: BorderRadius.circular(kRadius),
                            border: Border.all(color: kTeal.withOpacity(0.15)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: kTeal.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_location_alt_outlined, color: kTeal, size: 38),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No places added yet.',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Use the AI Planner to add places to this trip!',
                                style: TextStyle(fontSize: 13, color: kTeal),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Data — vertical timeline list
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        itemBuilder: (_, i) {
                          final place = places[i];
                          final isMap = place is Map<String, dynamic>;
                          final name = isMap ? (place['name']?.toString() ?? 'Place') : place.toString();
                          final location = isMap ? (place['location']?.toString() ?? '') : '';
                          final time = isMap ? (place['time']?.toString() ?? '') : '';
                          final desc = isMap ? (place['description']?.toString() ?? '') : '';
                          final rating = isMap ? _safeParseDouble(place['rating']) : null;
                          final isLast = i == places.length - 1;

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Timeline rail ────────────────────────
                                SizedBox(
                                  width: 32,
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: kTeal.withOpacity(0.15),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [kTeal.withOpacity(0.15), kTeal.withOpacity(0.15)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // ── Place card ───────────────────────────
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF172A46),
                                      borderRadius: BorderRadius.circular(kRadius),
                                      border: Border.all(color: kTeal.withOpacity(0.15)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // name + time row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            if (time.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: kTeal.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: kTeal.withOpacity(0.15)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.access_time_rounded, color: kTeal, size: 11),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      time,
                                                      style: const TextStyle(color: kTeal, fontSize: 11, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        // location
                                        if (location.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_rounded, color: kTeal, size: 12),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  location,
                                                  style: const TextStyle(color: kTeal, fontSize: 12, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        // description
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            desc,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.15),
                                              height: 1.5,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        // rating
                                        if (rating != null) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              ...List.generate(5, (star) {
                                                return Icon(
                                                  star < rating.round()
                                                      ? Icons.star_rounded
                                                      : Icons.star_border_rounded,
                                                  color: const Color(0xFFF59E0B),
                                                  size: 14,
                                                );
                                              }),
                                              const SizedBox(width: 6),
                                              Text(
                                                rating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withOpacity(0.15),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
