import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/app_theme.dart';
import 'itinerary_screen.dart';
import '../services/ai_service.dart';
import '../models/itinerary_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/place_image_widget.dart';
import '../widgets/animated_card.dart';

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
        const SnackBar(
          content: Text('Destination and valid days required.'),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; _itinerary = null; });
    try {
      final itinerary = await _aiService.generateItinerary(location: destination, days: days);
      if (mounted) setState(() => _itinerary = itinerary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI is currently busy. Try again soon.'),
            backgroundColor: kDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Astral Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildOrb(),
                    const SizedBox(height: 16),
                    const Text(
                      'AI Planner',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kWhite,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Input Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Dream big. Our AI curates the details.',
                    style: TextStyle(
                      color: kWhite.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 32),
                  
                  _buildForm(),

                  if (_isLoading) _buildStardustLoader(),
                  
                  if (_itinerary != null) ...[
                    const SizedBox(height: 48),
                    _buildResults(),
                  ],

                  if (!_isLoading && _itinerary == null) ...[
                    const SizedBox(height: 60),
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: kTeal.withValues(alpha: 0.05),
                      size: 80,
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                  ],
                  
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [kTeal, Colors.transparent],
        ),
        boxShadow: [
          BoxShadow(
            color: kTeal.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds, curve: Curves.easeInOut);
  }

  Widget _buildForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Destination Autocomplete
          Autocomplete<String>(
            optionsBuilder: (v) => _fetchSuggestions(v.text),
            onSelected: (s) => _destCtrl.text = s,
            fieldViewBuilder: (ctx, ctrl, focus, onSubmitted) {
              ctrl.addListener(() => _destCtrl.text = ctrl.text);
              return _textField(
                controller: ctrl,
                focusNode: focus,
                hint: 'Destination (e.g. Kyoto)',
                icon: Icons.map_rounded,
              );
            },
            optionsViewBuilder: (ctx, onSelected, options) => _buildOptionsView(ctx, onSelected, options),
          ),
          
          const SizedBox(height: 16),
          
          // Row for Days and Go
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _textField(
                  controller: _daysCtrl,
                  hint: 'Days',
                  icon: Icons.timer_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'GO',
                  height: 54,
                  onPressed: _generateItinerary,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.2), fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: kTeal.withValues(alpha: 0.5), size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kWhite.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kTeal, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStardustLoader() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(3, (i) => Container(
              width: 100.0 + (i * 40),
              height: 100.0 + (i * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kTeal.withValues(alpha: 0.1 - (i * 0.03))),
              ),
            ).animate(onPlay: (c) => c.repeat()).scale(
              begin: const Offset(1, 1), 
              end: const Offset(1.2, 1.2), 
              duration: (1200 + (i * 400)).ms,
              curve: Curves.easeInOut,
            ).fadeOut()),
            
            const Icon(Icons.auto_awesome_rounded, color: kTeal, size: 40)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1.seconds, color: kWhite),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'CURATING YOUR ADVENTURE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
            color: kTeal.withValues(alpha: 0.6),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Proposed Itinerary',
              style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              radius: 20,
              child: Text(
                '${_itinerary?.days} DAYS',
                style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Staggered Day Cards
        ..._itinerary!.dayPlans.take(3).map((day) => AnimatedCard(
          index: day.day,
          child: _dayCard(day),
        )),

        const SizedBox(height: 24),
        CustomButton(
          text: 'View Full Journey',
          variant: ButtonVariant.secondary,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItineraryScreen(itinerary: _itinerary!)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _dayCard(DayPlan day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DAY ${day.day}: ${day.theme.toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: kWhite.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 16),
            ...day.activities.take(2).map((a) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 54, 
                  height: 54, 
                  child: PlaceImageWidget(placeName: a.name, cityName: _destCtrl.text),
                ),
              ),
              title: Text(
                a.name,
                style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                a.time,
                style: const TextStyle(color: kTeal, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, color: kWhite.withValues(alpha: 0.1), size: 14),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsView(BuildContext ctx, Function(String) onSelected, Iterable<String> options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(ctx).size.width - 48,
          margin: const EdgeInsets.only(top: 8),
          child: GlassContainer(
            padding: EdgeInsets.zero,
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
