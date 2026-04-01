import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:waygo_app/config/app_theme.dart";
import "package:waygo_app/screens/ai_planner_screen.dart";
import "package:waygo_app/screens/saved_trip_details_screen.dart";
import "package:waygo_app/services/auth_service.dart";
import "package:waygo_app/services/trip_service.dart";
import "package:waygo_app/widgets/glass_container.dart";
import "package:waygo_app/widgets/custom_button.dart";
import "package:flutter/services.dart"; // Core services integrated

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _tripService = const TripService();
  final _authService = const AuthService();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;
  bool _isTripSaved = false;
  int? _newTripId;

  @override
  void dispose() {
    _tripNameController.dispose();
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
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: kTeal, onPrimary: kWhite, surface: kSurface, onSurface: kWhite),
            dialogTheme: const DialogThemeData(backgroundColor: kSurface),
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
    if (_startDate == null || _endDate == null) return;

    setState(() => _isCreating = true);
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize journey. Checking connection...'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      setState(() => _isCreating = false);
      return;
    }
    final userId = int.tryParse(userIdStr) ?? 0;
    final token = await _authService.getToken();
    
    try {
      final tripId = await _tripService.createTrip(
        userId: userId,
        name: _tripNameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        token: token,
      );

      if (mounted) {
        if (tripId != null) {
          setState(() {
            _isCreating = false;
            _isTripSaved = true;
            _newTripId = tripId;
          });
          HapticFeedback.vibrate();
        } else {
          throw Exception('Creation failed');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deep systems check failed. Please try again.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_isTripSaved),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
        ),
        title: Text(
          _isTripSaved ? "CONGRATULATIONS" : "NEW EXPEDITION",
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
        ),
      ),
      body: AnimatedSwitcher(
        duration: 600.ms,
        child: _isTripSaved ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Where shall we take you?',
              style: TextStyle(color: kWhite, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
            ).animate().fadeIn().slideX(begin: -0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              'Define your next masterpiece journey.',
              style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 14),
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 48),
            
            _fieldHeader('EXPEDITION NAME'),
            const SizedBox(height: 12),
            GlassContainer(
              padding: EdgeInsets.zero,
              radius: 16,
              child: TextFormField(
                controller: _tripNameController,
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'e.g. Autumn in Kyoto',
                  hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.2)),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: kTeal, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
                validator: (v) => (v?.length ?? 0) < 3 ? 'Too short' : null,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
            
            _fieldHeader('TIMELINE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _dateTile('DEPARTURE', _startDate, () => _pickDate(true))),
                const SizedBox(width: 16),
                Expanded(child: _dateTile('RETURN', _endDate, () => _pickDate(false))),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 60),
            
            CustomButton(
              text: 'Initialize Journey',
              isLoading: _isCreating,
              onPressed: _createTrip,
            ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          ],
        ),
      ),
    );
  }

  Widget _fieldHeader(String text) {
    return Text(
      text,
      style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(
              _formatDate(date),
              style: TextStyle(color: date == null ? kWhite.withValues(alpha: 0.2) : kWhite, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kTeal.withValues(alpha: 0.2), width: 2),
              boxShadow: [
                BoxShadow(color: kTeal.withValues(alpha: 0.2), blurRadius: 40),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: kTeal, size: 60),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack).shimmer(delay: 800.ms),
          
          const SizedBox(height: 48),
          
          const Text(
            'EXPEDITION READY',
            style: TextStyle(color: kWhite, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1),
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 12),
          
          Text(
            'Your luxury itinerary platform is now initialized. How would you like to proceed?',
            textAlign: TextAlign.center,
            style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 14, height: 1.5),
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 60),
          
          CustomButton(
            text: 'Summon AI Planner ✨',
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AiPlannerScreen())),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: 16),
          
          CustomButton(
            text: 'Manual Curation',
            variant: ButtonVariant.secondary,
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => SavedTripDetailsScreen(tripId: _newTripId!, tripName: _tripNameController.text.trim())),
            ),
          ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
