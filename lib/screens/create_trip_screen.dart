import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:waygo_app/config/app_theme.dart";
import "package:waygo_app/screens/ai_planner_screen.dart";
import "package:waygo_app/screens/saved_trip_details_screen.dart";
import "package:waygo_app/services/auth_service.dart";
import "package:waygo_app/services/trip_service.dart";

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _tripService = const TripService();
  final _authService = const AuthService();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;

  // ── Success state ─────────────────────────────────────────────────────────
  bool _isTripSaved = false;
  int? _newTripId;

  // ── Animation controller for success view ─────────────────────────────────
  late final AnimationController _successAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _successAnim, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Select date";
    return DateFormat("dd MMM yyyy").format(date);
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: kTeal),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createTrip() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startDate == null || _endDate == null) {
      _showSnackBar("Please select both start and end dates");
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showSnackBar("End date cannot be before start date");
      return;
    }

    setState(() => _isCreating = true);

    try {
      final userIdStr = await _authService.getUserId();
      final userId = int.tryParse(userIdStr ?? '1') ?? 1;
      
      final token = await _authService.getToken();
      
      final tripId = await _tripService.createTrip(
        userId: userId,
        name: _tripNameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        token: token,
      );

      if (!mounted) return;
      setState(() => _isCreating = false);

      if (tripId != null) {
        // ✅ Success — update state and trigger animation
        setState(() {
          _isTripSaved = true;
          _newTripId = tripId;
        });
        _successAnim.forward();
      } else {
        _showSnackBar("Failed to create trip. Check your server connection.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        _showSnackBar("An unexpected error occurred.");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: kNavy2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_isTripSaved),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
        ),
        title: Text(
          _isTripSaved ? "Trip Created!" : "Plan New Journey",
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _isTripSaved
              ? _buildSuccessView()
              : _buildFormView(),
        ),
      ),
    );
  }

  // ── Form View ─────────────────────────────────────────────────────────────
  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // ── Header ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kTeal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: kTealGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: kTeal.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.flight_takeoff_rounded, color: kWhite, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Trip Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
                          SizedBox(height: 2),
                          Text("Fill in the details to create your trip", style: TextStyle(fontSize: 12, color: kSlate)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Trip Name ────────────────────────────────────────────────
              const Text(
                "TRIP NAME",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kTeal, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: kNavy2,
                  borderRadius: BorderRadius.circular(kRadius12),
                  border: Border.all(color: kWhite.withOpacity(0.08)),
                ),
                child: TextFormField(
                  controller: _tripNameController,
                  style: const TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w600),
                  cursorColor: kTeal,
                  decoration: InputDecoration(
                    hintText: "E.g. Manali Adventure 2026",
                    hintStyle: TextStyle(color: kSlate.withOpacity(0.7), fontSize: 14),
                    prefixIcon: const Icon(Icons.edit_rounded, color: kTeal, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if ((value?.trim() ?? "").length < 3) return "Name must be at least 3 characters";
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Dates ────────────────────────────────────────────────────
              const Text(
                "TRAVEL DATES",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kTeal, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _DateTile(label: "Start Date", value: _formatDate(_startDate), onTap: () => _pickDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _DateTile(label: "End Date", value: _formatDate(_endDate), onTap: () => _pickDate(false))),
                ],
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: kTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kTeal.withOpacity(0.3)),
                    ),
                    child: Text(
                      "${_endDate!.difference(_startDate!).inDays + 1} days trip",
                      style: const TextStyle(color: kTeal, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // ── Save Button ──────────────────────────────────────────────
              GestureDetector(
                onTap: _isCreating ? null : _createTrip,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: _isCreating
                        ? LinearGradient(colors: [kTeal.withOpacity(0.5), kTeal.withOpacity(0.3)])
                        : kTealGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _isCreating
                        ? []
                        : [BoxShadow(color: kTeal.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _isCreating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2.5)),
                              SizedBox(width: 12),
                              Text("Creating Trip…", style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch_rounded, color: kWhite, size: 20),
                              SizedBox(width: 10),
                              Text("Create Trip", style: TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                            ],
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

  // ── Success View ──────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return FadeTransition(
      key: const ValueKey('success'),
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Success Icon ─────────────────────────────────────────────
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kTeal.withOpacity(0.12),
                  border: Border.all(color: kTeal.withOpacity(0.4), width: 2),
                  boxShadow: [BoxShadow(color: kTeal.withOpacity(0.25), blurRadius: 30, spreadRadius: 4)],
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: kTeal, size: 66),
              ),
            ),
            const SizedBox(height: 28),

            // ── Title ────────────────────────────────────────────────────
            const Text(
              "Trip Created\nSuccessfully!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kWhite, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              "\"${_tripNameController.text.trim()}\" is ready.\nChoose how you want to fill your itinerary.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: kSlate, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 48),

            // ── Button 1: Add Places Manually ────────────────────────────
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SavedTripDetailsScreen(
                      tripId: _newTripId!,
                      tripName: _tripNameController.text.trim(),
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kTeal, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_location_alt_rounded, color: kTeal, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Add Places Manually",
                      style: TextStyle(color: kTeal, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Button 2: AI Planner ─────────────────────────────────────
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AiPlannerScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: kTealGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kTeal.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: kWhite, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Plan your trip with WayGo ✨",
                      style: TextStyle(color: kWhite, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Tile Widget ──────────────────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDate = value != "Select date";
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kNavy2,
          borderRadius: BorderRadius.circular(kRadius12),
          border: Border.all(
            color: hasDate ? kTeal.withOpacity(0.5) : kWhite.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: hasDate ? kTeal : kSlate),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: kSlate, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasDate ? kWhite : kSlate,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
