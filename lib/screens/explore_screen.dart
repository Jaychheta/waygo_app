import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/animated_card.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = [
      {'name': 'Surat', 'img': 'https://images.unsplash.com/photo-1597058620222-682559de4770?auto=format&fit=crop&w=400'},
      {'name': 'Delhi', 'img': 'https://images.unsplash.com/photo-1587474260584-136574528ed5?auto=format&fit=crop&w=400'},
      {'name': 'Mumbai', 'img': 'https://images.unsplash.com/photo-1562330203-0ed7f48425ed?auto=format&fit=crop&w=400'},
      {'name': 'Udaipur', 'img': 'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?auto=format&fit=crop&w=400'},
    ];

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('EXPLORE DESTINATIONS', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Trending Cities',
              style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: list.length,
              itemBuilder: (ctx, i) => AnimatedCard(
                index: i,
                child: _buildCityCard(list[i]['name']!, list[i]['img']!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(String name, String img) {
    return Container(
      decoration: BoxDecoration(
        color: kNavy2,
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover, opacity: 0.5),
      ),
      child: Center(
        child: Text(
          name.toUpperCase(),
          style: const TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
        ),
      ),
    );
  }
}
