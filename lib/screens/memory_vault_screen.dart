import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../models/memory_model.dart';
import '../services/auth_service.dart';
import '../services/memory_service.dart';
import '../services/trip_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_card.dart';

class MemoryVaultScreen extends StatefulWidget {
  const MemoryVaultScreen({super.key});

  @override
  State<MemoryVaultScreen> createState() => _MemoryVaultScreenState();
}

class _MemoryVaultScreenState extends State<MemoryVaultScreen> {
  final _picker = ImagePicker();
  final _memoryService = const MemoryService();
  final _authService = const AuthService();
  
  Future<List<MemoryModel>>? _memoriesFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _refreshMemories();
  }

  void _refreshMemories() {
    setState(() {
      _memoriesFuture = _fetchMemories();
    });
  }

  Future<List<MemoryModel>> _fetchMemories() async {
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null) return [];
    final userId = int.tryParse(userIdStr) ?? 0;
    return _memoryService.getMemories(userId);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final userIdStr = await _authService.getUserId();
      if (userIdStr == null) return;
      final userId = int.tryParse(userIdStr) ?? 0;
      final token = await _authService.getToken();
      
      // 1. Fetch available trips for selection
      final trips = await const TripService().getUserTrips(userId, token: token);
      if (!mounted) return;

      String? selectedTrip;
      if (trips.isNotEmpty) {
        selectedTrip = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: kSurface2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Capture Memory For', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: trips.length,
                itemBuilder: (c, i) => ListTile(
                  leading: const Icon(Icons.flight_takeoff_rounded, color: kTeal),
                  title: Text(trips[i].name, style: const TextStyle(color: kWhite)),
                  subtitle: Text(trips[i].location, style: TextStyle(color: kWhite.withValues(alpha: 0.3))),
                  onTap: () => Navigator.pop(c, trips[i].name),
                ),
              ),
            ),
          ),
        );
      }
      
      final tripName = selectedTrip ?? 'Global Expedition';
      if (selectedTrip == null && trips.isNotEmpty) return; // User cancelled

      // 2. Pick photo
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;

      setState(() => _isUploading = true);
      
      final bytes = await file.readAsBytes();
      final success = await _memoryService.uploadMemory(
        userId: userId,
        tripName: tripName,
        imageBytes: bytes.toList(),
        fileName: file.name,
      );

      if (success) {
        _refreshMemories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory safe in the vault!'), backgroundColor: kTeal, behavior: SnackBarBehavior.floating),
        );
      }
      
      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          FutureBuilder<List<MemoryModel>>(
            future: _memoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kTeal)));
              }
              final memories = snapshot.data ?? [];
              if (memories.isEmpty) return SliverFillRemaining(child: _buildEmptyState());

              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  itemBuilder: (context, index) => AnimatedCard(
                    index: index,
                    child: _memoryPolaroid(memories[index]),
                  ),
                  childCount: memories.length,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickPhoto(ImageSource.gallery),
        backgroundColor: kTeal,
        child: _isUploading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
          : const Icon(Icons.add_a_photo_rounded, color: kWhite),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: kSurface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: const Text(
          'Memory Vault',
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1),
        ),
        background: Stack(
          alignment: Alignment.centerRight,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 40),
              child: const Icon(Icons.camera_rounded, color: kTeal, size: 100).animate().fadeIn().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memoryPolaroid(MemoryModel memory) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: memory.imageUrl.startsWith('http') 
                ? Image.network(memory.imageUrl, fit: BoxFit.cover)
                : Image.file(File(memory.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.tripName.toUpperCase(),
                  style: const TextStyle(color: kTeal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(memory.date),
                  style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_rounded, color: kTeal, size: 80).animate().shake(),
          const SizedBox(height: 24),
          const Text(
            'The vault is empty.',
            style: TextStyle(color: kWhite, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Freeze a moment in time.',
            style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
