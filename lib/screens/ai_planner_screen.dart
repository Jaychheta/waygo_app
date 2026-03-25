import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:waygo_app/config/api_config.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/screens/itinerary_screen.dart';
import 'package:waygo_app/services/ai_service.dart';
import 'package:waygo_app/models/itinerary_model.dart';
import 'package:waygo_app/widgets/custom_button.dart';
import 'package:waygo_app/services/place_image_service.dart';

class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _aiService = const AiService();
  final _destCtrl = TextEditingController();
  
  final _daysCtrl = TextEditingController(text: '3');
  bool _isLoading = false;
  ItineraryModel? _itinerary;

  @override
  void dispose() {
    _destCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateItinerary() async {
    final destination = _destCtrl.text.trim();
    final daysStr = _daysCtrl.text.trim();
    final days = int.tryParse(daysStr) ?? 0;

    if (destination.isEmpty || days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter destination and valid number of days'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; _itinerary = null; });
    try {
      final itinerary = await _aiService.generateItinerary(location: destination, days: days);
      if (mounted) setState(() => _itinerary = itinerary);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildInputs(),
                    if (_isLoading) const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: kTeal)),
                    if (_itinerary != null) ...[
                      const SizedBox(height: 32),
                      _buildResultsHeader(),
                      const SizedBox(height: 16),
                      ..._itinerary!.dayPlans.take(1).map((d) => _miniDayPreview(d)).toList(),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ItineraryScreen(itinerary: _itinerary!))),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('View Full Detailed Plan', style: TextStyle(color: kTeal, fontWeight: FontWeight.bold)), Icon(Icons.chevron_right, color: kTeal)]),
                      ),
                    ] else if (!_isLoading) ...[
                      const SizedBox(height: 100),
                      Icon(Icons.auto_awesome_outlined, color: kWhite.withOpacity(0.05), size: 120),
                      const SizedBox(height: 20),
                      Text('Start your AI journey', style: TextStyle(color: kWhite.withOpacity(0.2), fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          const Expanded(child: Text('WayGo AI Planner', style: TextStyle(color: kWhite, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kWhite.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, color: kWhite, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue value) => _fetchSuggestions(value.text),
          onSelected: (String s) => _destCtrl.text = s,
          fieldViewBuilder: (ctx, ctrl, focus, onSubmitted) {
            ctrl.addListener(() => _destCtrl.text = ctrl.text);
            if (_destCtrl.text.isNotEmpty && ctrl.text.isEmpty) ctrl.text = _destCtrl.text;
            return TextField(
              controller: ctrl,
              focusNode: focus,
              style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Where to next?',
                hintStyle: const TextStyle(color: kSlate),
                prefixIcon: const Icon(Icons.location_on_rounded, color: kTeal, size: 18),
                filled: true,
                fillColor: kWhite.withOpacity(0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: kWhite.withOpacity(0.05))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            );
          },
          optionsViewBuilder: (ctx, onSelected, options) => _buildOptionsView(ctx, onSelected, options),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _daysCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'No. of Days',
                  hintStyle: const TextStyle(color: kSlate),
                  prefixIcon: const Icon(Icons.timer_outlined, color: kTeal, size: 18),
                  filled: true,
                  fillColor: kWhite.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: kWhite.withOpacity(0.05))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _generateItinerary,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kTeal,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kTeal.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: kWhite, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Your Trip Plan', style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w800)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: kTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('${_itinerary?.days} Days', style: const TextStyle(color: kTeal, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _miniDayPreview(DayPlan day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Day ${day.day}: ${day.theme}', style: const TextStyle(color: kSlate, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        ...day.activities.take(2).map((a) => _activityTile(a)).toList(),
      ],
    );
  }

  Widget _activityTile(Activity a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kNavy2, borderRadius: BorderRadius.circular(20), border: Border.all(color: kWhite.withOpacity(0.05))),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 60, height: 60, child: PlaceImageWidget(placeName: a.name, cityName: _destCtrl.text))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(a.time, style: const TextStyle(color: kTeal, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.favorite_border_rounded, color: kSlate, size: 18),
        ],
      ),
    );
  }

  // --- Helper Methods ---


  Widget _buildOptionsView(BuildContext ctx, Function(String) onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(ctx).size.width - 48,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(color: kNavy2, borderRadius: BorderRadius.circular(20), border: Border.all(color: kWhite.withOpacity(0.1)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (ctx, i) {
              final option = options.elementAt(i);
              return ListTile(
                title: Text(option, style: const TextStyle(color: kWhite, fontSize: 14)),
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<String>> _fetchSuggestions(String query) async {
    if (query.length < 2) return [];
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('${ApiConfig.baseUrl}/search-cities?q=$encodedQuery');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body)['results'];
        return results.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) { return []; }
  }
}

class CategoryBadge extends StatelessWidget {
  final String category;
  const CategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    Color color = kTeal; IconData icon = Icons.info_outline_rounded;
    if (category.toLowerCase().contains('food')) { color = const Color(0xFFF59E0B); icon = Icons.restaurant_rounded;
    } else if (category.toLowerCase().contains('walk')) { color = const Color(0xFF10B981); icon = Icons.directions_walk_rounded;
    } else if (category.toLowerCase().contains('photo')) { color = const Color(0xFF6366F1); icon = Icons.camera_alt_rounded; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 12), const SizedBox(width: 6), Text(category, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))]),
    );
  }
}

class PlaceImageWidget extends StatefulWidget {
  final String placeName;
  final String cityName;
  final String category;
  final String description;

  const PlaceImageWidget({super.key, required this.placeName, required this.cityName, this.category = '', this.description = ''});

  @override
  State<PlaceImageWidget> createState() => _PlaceImageWidgetState();
}

class _PlaceImageWidgetState extends State<PlaceImageWidget> {
  String? _imageUrl; bool _loading = true;

  @override
  void initState() { super.initState(); _loadImage(); }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final url = await PlaceImageService.instance.fetchImage(placeName: widget.placeName, cityName: widget.cityName, category: widget.category, description: widget.description);
    if (mounted) setState(() { _imageUrl = url; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Container(color: kNavy3, child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))));
    return Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => Container(color: kNavy3, child: Icon(Icons.broken_image_outlined, color: kSlate.withOpacity(0.3), size: 30)));
  }
}
