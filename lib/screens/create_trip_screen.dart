import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:waygo_app/services/trip_service.dart"; 
import "package:waygo_app/widgets/custom_button.dart";

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _tripService = const TripService(); 

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCreating = false;

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
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF2563EB),
                ),
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
    // ફોર્મ વેલિડેશન ચેક
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // તારીખ સિલેક્ટ કરી છે કે નહીં તે ચેક
    if (_startDate == null || _endDate == null) {
      _showSnackBar("Please select both start and end dates");
      return;
    }

    // એન્ડ ડેટ સ્ટાર્ટ ડેટ પહેલા ના હોવી જોઈએ
    if (_endDate!.isBefore(_startDate!)) {
      _showSnackBar("End date cannot be before start date");
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Backend API માં ડેટા મોકલો
      // નોંધ: હાલમાં userId: 1 વાપરીએ છીએ જે pgAdmin માં ચેક કર્યું હતું
      final success = await _tripService.createTrip(
        userId: 1, 
        name: _tripNameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted) return;
      setState(() => _isCreating = false);

      if (success) {
        _showSnackBar("Trip created successfully in database! ✅");
        // ડેટાબેઝમાં સેવ થયા પછી ડેશબોર્ડ પર પાછા જાઓ
        Navigator.of(context).pop(true); 
      } else {
        _showSnackBar("Failed to create trip. Check your server connection.");
      }
    } catch (e) {
      setState(() => _isCreating = false);
      _showSnackBar("An unexpected error occurred.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061026), // ડાર્ક થીમ મુજબ બેકગ્રાઉન્ડ
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Plan New Journey"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trip Details",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _tripNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Trip Name",
                      hintText: "E.g. Manali Adventure 2026",
                      labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E293B))),
                    ),
                    validator: (value) {
                      if ((value?.trim() ?? "").length < 3) return "Name is too short";
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _DateTile(
                    label: "Start Date",
                    value: _formatDate(_startDate),
                    onTap: () => _pickDate(true),
                  ),
                  const SizedBox(height: 16),
                  _DateTile(
                    label: "End Date",
                    value: _formatDate(_endDate),
                    onTap: () => _pickDate(false),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: "Save Trip to Database",
                    isLoading: _isCreating,
                    onPressed: _createTrip,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF12203D),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 22, color: Color(0xFF2563EB)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.edit_calendar_rounded, color: Colors.white24, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}