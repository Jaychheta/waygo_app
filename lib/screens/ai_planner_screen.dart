import 'package:flutter/material.dart';
import 'package:waygo_app/config/app_theme.dart';
import 'package:waygo_app/models/itinerary_model.dart';
import 'package:waygo_app/screens/itinerary_screen.dart';
import 'package:waygo_app/services/ai_service.dart';
import 'package:waygo_app/widgets/custom_button.dart';

class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final _locationCtrl = TextEditingController();
  final _aiService = const AiService();

  int _days = 3;
  int _selectedDay = 0;
  bool _isLoading = false;
  ItineraryModel? _itinerary;

  final List<String> _addedActivities = [];

  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 10));

  static const List<String> _popularCities = [
    // India
    'Surat', 'Mumbai', 'Goa', 'Manali', 'Delhi', 'Jaipur', 'Agra',
    'Varanasi', 'Udaipur', 'Rishikesh', 'Shimla', 'Darjeeling',
    'Amritsar', 'Mysuru', 'Coorg', 'Ooty', 'Kolkata', 'Hyderabad',
    'Bengaluru', 'Kochi', 'Leh', 'Spiti Valley', 'Rann of Kutch',
    'Andaman Islands', 'Pondicherry',
    // Asia
    'Dubai', 'Singapore', 'Bangkok', 'Bali', 'Tokyo', 'Kyoto',
    'Kathmandu', 'Colombo', 'Maldives', 'Hong Kong', 'Kuala Lumpur',
    'Phuket', 'Seoul', 'Hanoi',
    // Europe
    'Paris', 'London', 'Rome', 'Barcelona', 'Amsterdam', 'Prague',
    'Vienna', 'Santorini', 'Venice', 'Zurich',
    // Americas & Others
    'New York', 'Sydney', 'Cape Town', 'Toronto', 'Istanbul',
  ];


  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a destination'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() { _isLoading = true; _itinerary = null; _selectedDay = 0; });

    try {
      final result = await _aiService.generateItinerary(
        location: _locationCtrl.text.trim(),
        days: _days,
      );
      if (mounted) setState(() { _itinerary = result; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not connect to server. Please try again.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: kTeal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _days = _endDate.difference(_startDate).inDays.clamp(1, 14);
        } else {
          _endDate = picked;
          _days = _endDate.difference(_startDate).inDays.clamp(1, 14);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _itinerary == null
                      ? _buildInputView()
                      : _buildItineraryView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text('WayGo AI Planner', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kWhite)),
          const Spacer(),
          Icon(Icons.notifications_outlined, color: kSlate, size: 24),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: glowDecor(radius: 50),
            child: const Icon(Icons.auto_awesome, color: kWhite, size: 40),
          ),
          const SizedBox(height: 24),
          const Text('AI is planning...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kWhite)),
          const SizedBox(height: 10),
          const Text('Fetching the best experiences for you', style: TextStyle(color: kSlate, fontSize: 13)),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: kTeal, strokeWidth: 3),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Location autocomplete
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue v) {
              if (v.text.isEmpty) return const Iterable<String>.empty();
              return _popularCities.where((city) =>
                  city.toLowerCase().contains(v.text.toLowerCase()));
            },
            onSelected: (String city) {
              _locationCtrl.text = city;
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              // Mirror any external changes (e.g. clearing) back to _locationCtrl
              controller.addListener(() => _locationCtrl.text = controller.text);
              return Container(
                decoration: BoxDecoration(
                  color: kNavy2,
                  borderRadius: BorderRadius.circular(kRadius12),
                  border: Border.all(color: kWhite.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(color: kWhite, fontSize: 15),
                  onSubmitted: (_) => onSubmitted(),
                  decoration: const InputDecoration(
                    hintText: 'Where do you want to go?',
                    hintStyle: TextStyle(color: kSlate),
                    prefixIcon: Icon(Icons.location_on_outlined, color: kTeal, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    margin: const EdgeInsets.only(top: 4, right: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F38),
                      borderRadius: BorderRadius.circular(kRadius12),
                      border: Border.all(color: kTeal.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(kRadius12),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: kWhite.withValues(alpha: 0.05)),
                        itemBuilder: (context, i) {
                          final city = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(city),
                            splashColor: kTeal.withValues(alpha: 0.1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: kTeal, size: 15),
                                  const SizedBox(width: 10),
                                  Text(
                                    city,
                                    style: const TextStyle(color: kWhite, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Date pickers row
          Row(
            children: [
              Expanded(child: _dateTile(_startDate, true)),
              const SizedBox(width: 12),
              Expanded(child: _dateTile(_endDate, false)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _generate,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadius12), gradient: kTealGradient),
                  child: const Icon(Icons.auto_fix_high_rounded, color: kWhite, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: kTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.explore_rounded, color: kTeal, size: 48),
                ),
                const SizedBox(height: 20),
                const Text('Plan your perfect trip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWhite)),
                const SizedBox(height: 8),
                const Text('Enter a destination and dates above,\nthen tap the ✨ button to generate your AI itinerary.',
                    textAlign: TextAlign.center, style: TextStyle(color: kSlate, fontSize: 14, height: 1.5)),
                const SizedBox(height: 32),
                CustomButton(text: 'Generate Itinerary ✨', onPressed: _generate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: kNavy2,
          borderRadius: BorderRadius.circular(kRadius12),
          border: Border.all(color: kWhite.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: kSlate, size: 14),
            const SizedBox(width: 8),
            Text(
              '${date.day} ${_month(date.month)}',
              style: const TextStyle(color: kWhite, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  Widget _buildItineraryView() {
    final plan = _itinerary!.dayPlans[_selectedDay];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_itinerary!.location,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWhite)),
                    Text('${_itinerary!.days}-day itinerary',
                        style: const TextStyle(color: kSlate, fontSize: 13)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _itinerary = null),
                icon: const Icon(Icons.refresh_rounded, color: kTeal, size: 18),
                label: const Text('Redo', style: TextStyle(color: kTeal, fontSize: 13)),
              ),
            ],
          ),
        ),

        // ── View Full Timeline button ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ItineraryScreen(
                  location: _itinerary!.location,
                  days: _itinerary!.days,
                  tripName: _itinerary!.location,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: kTealGradient,
                borderRadius: BorderRadius.circular(kRadius12),
                boxShadow: [BoxShadow(color: kTeal.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_timeline_rounded, color: kWhite, size: 18),
                  SizedBox(width: 8),
                  Text('View Full Timeline', style: TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: kWhite, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Day tab chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _itinerary!.dayPlans.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = i == _selectedDay;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? kTealGradient : null,
                    color: selected ? null : kNavy2,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selected ? Colors.transparent : kWhite.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'Day ${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? kWhite : kSlate,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Day theme label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('Day ${plan.day}  ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kWhite)),
              Text(plan.theme, style: const TextStyle(fontSize: 15, color: kTeal, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${plan.activities.length} Places', style: const TextStyle(color: kSlate, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Activities timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: plan.activities.length,
            itemBuilder: (_, i) => _activityCard(plan.activities[i]),
          ),
        ),
      ],
    );
  }

  Widget _activityCard(Activity activity) {
    final added = _addedActivities.contains(activity.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kWhite.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius)),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: kNavy3,
                  child: const Icon(Icons.image_rounded, color: kSlate, size: 48),
                ),
              ),
              // Time badge
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: kTeal, size: 12),
                      const SizedBox(width: 4),
                      Text(activity.time, style: const TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              if (activity.isPopular)
                Positioned(
                  top: 12, left: 110,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(20)),
                    child: const Text('POPULAR', style: TextStyle(color: kWhite, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              // Rating
              Positioned(
                bottom: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 3),
                      Text(activity.rating.toStringAsFixed(1), style: const TextStyle(color: kWhite, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kWhite)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: kSlate, size: 13),
                    const SizedBox(width: 4),
                    Text(activity.location, style: const TextStyle(color: kSlate, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(activity.description, style: const TextStyle(color: kSlate, fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (added) {
                              _addedActivities.remove(activity.name);
                            } else {
                              _addedActivities.add(activity.name);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(added ? 'Removed from itinerary' : '${activity.name} added to itinerary ✓'),
                              backgroundColor: added ? Colors.red.shade800 : kTeal,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: added ? null : kTealGradient,
                            color: added ? kNavy3 : null,
                            borderRadius: BorderRadius.circular(kRadius12),
                            border: added ? Border.all(color: kTeal.withValues(alpha: 0.4)) : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(added ? Icons.check_rounded : Icons.add_rounded, color: added ? kTeal : kWhite, size: 18),
                              const SizedBox(width: 6),
                              Text(added ? 'Added to Itinerary' : 'Add to Itinerary',
                                  style: TextStyle(color: added ? kTeal : kWhite, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: kNavy3, borderRadius: BorderRadius.circular(kRadius12)),
                      child: const Icon(Icons.map_outlined, color: kSlate, size: 18),
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
