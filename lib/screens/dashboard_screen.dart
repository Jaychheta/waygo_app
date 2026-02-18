import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:waygo_app/screens/create_trip_screen.dart";
import "package:waygo_app/screens/login_screen.dart";
import "package:waygo_app/services/auth_service.dart";
import "package:waygo_app/widgets/custom_button.dart";

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName = "User"});

  static const String routeName = "/dashboard";
  final String userName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = const AuthService();
  int _selectedIndex = 0;

  int _totalTrips = 4;
  final int _totalExpenses = 2480;
  int _upcomingTrips = 2;
  final List<_TripItem> _recentTrips = [
    _TripItem(
      name: "Santorini Escape",
      location: "Greece",
      dateRange: "12 Apr - 18 Apr",
      expense: "\$920",
      status: "Upcoming",
    ),
    _TripItem(
      name: "Kyoto Culture Tour",
      location: "Japan",
      dateRange: "03 Mar - 10 Mar",
      expense: "\$1,240",
      status: "Planning",
    ),
    _TripItem(
      name: "Swiss Alps Trail",
      location: "Switzerland",
      dateRange: "22 May - 30 May",
      expense: "\$1,780",
      status: "Upcoming",
    ),
  ];

  Future<void> _openCreateTrip() async {
    final result = await Navigator.of(
      context,
    ).push<Map<String, dynamic>>(_slideRoute(const CreateTripScreen()));

    if (result == null || !mounted) {
      return;
    }

    final startDate = result["startDate"] as DateTime;
    final endDate = result["endDate"] as DateTime;
    final dateFormat = DateFormat("dd MMM");
    final dateRange =
        "${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}";

    setState(() {
      _recentTrips.insert(
        0,
        _TripItem(
          name: result["name"] as String,
          location: "Custom Destination",
          dateRange: dateRange,
          expense: "\$0",
          status: "Planning",
        ),
      );
      _totalTrips += 1;
      _upcomingTrips += 1;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Trip created successfully")));
  }

  Future<void> _logout() async {
    await _authService.clearToken();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(_fadeRoute(const LoginScreen()));
  }

  Route<T> _slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        final offset =
            Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: offset, child: page);
      },
    );
  }

  Route<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(opacity: animation, child: page);
      },
    );
  }

  Widget _buildHome() {
    final stats = [
      _StatData(title: "Trips", value: _totalTrips.toString(), icon: Icons.map),
      _StatData(
        title: "Expenses",
        value: "\$$_totalExpenses",
        icon: Icons.account_balance_wallet_rounded,
      ),
      _StatData(
        title: "Upcoming",
        value: _upcomingTrips.toString(),
        icon: Icons.flight_takeoff_rounded,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text(
          "Hello, ${widget.userName} \u{1F44B}",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          "Ready for your next premium adventure?",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        const SizedBox(height: 18),
        CustomButton(text: "Create New Trip", onPressed: _openCreateTrip),
        const SizedBox(height: 20),
        const Text(
          "Quick Stats",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 460;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((stat) {
                final cardWidth = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 3;
                return SizedBox(
                  width: cardWidth,
                  child: _StatCard(data: stat),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 22),
        const Text(
          "Recent Trips",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ..._recentTrips.map((trip) => _TripCard(trip: trip)),
      ],
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF14B8A6)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            if (title == "Profile") ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                child: OutlinedButton(
                  onPressed: _logout,
                  child: const Text("Logout"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHome(),
      _buildPlaceholder(
        icon: Icons.luggage_rounded,
        title: "Trips",
        subtitle: "Your itinerary collections and day-by-day plans show here.",
      ),
      _buildPlaceholder(
        icon: Icons.pie_chart_rounded,
        title: "Expenses",
        subtitle: "Track budgets, payments, and shared costs for every trip.",
      ),
      _buildPlaceholder(
        icon: Icons.person_rounded,
        title: "Profile",
        subtitle: "Manage your account details and travel preferences.",
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF061026), Color(0xFF0B1730)],
          ),
        ),
        child: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: screens),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTrip,
        backgroundColor: const Color(0xFF14B8A6),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0C1730),
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF14B8A6),
          unselectedItemColor: const Color(0xFF94A3B8),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.luggage_rounded),
              label: "Trips",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: "Expenses",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C36),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: const Color(0xFF14B8A6), size: 20),
            const SizedBox(height: 14),
            Text(
              data.value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(data.title, style: const TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}

class _TripItem {
  const _TripItem({
    required this.name,
    required this.location,
    required this.dateRange,
    required this.expense,
    required this.status,
  });

  final String name;
  final String location;
  final String dateRange;
  final String expense;
  final String status;
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final _TripItem trip;

  @override
  Widget build(BuildContext context) {
    final statusColor = trip.status == "Upcoming"
        ? const Color(0xFF22C55E)
        : const Color(0xFF38BDF8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1C36),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trip.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${trip.location} | ${trip.dateRange}",
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF14B8A6),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trip.expense,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
