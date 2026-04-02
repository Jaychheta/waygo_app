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
import '../config/api_config.dart';

class MemoryVaultScreen extends StatefulWidget {
  final String? filterTripName;
  const MemoryVaultScreen({super.key, this.filterTripName});

  @override
  State<MemoryVaultScreen> createState() => _MemoryVaultScreenState();
}

class _MemoryVaultScreenState extends State<MemoryVaultScreen> {
  final _picker = ImagePicker();
  final _memoryService = const MemoryService();
  final _authService = const AuthService();
  
  Future<List<MemoryModel>>? _memoriesFuture;
  bool _isUploading = false;
  String? _localTripFilter;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _refreshMemories();
  }

  void _refreshMemories() {
    setState(() {
      _memoriesFuture = _fetchMemories();
    });
  }

  Future<void> _loadMyId() async {
    final id = await _authService.getUserId();
    setState(() => _myId = id);
  }

  Future<List<MemoryModel>> _fetchMemories() async {
    // If we're inside a specific trip folder — fetch ALL members' memories for that trip
    final activeTripFilter = widget.filterTripName ?? _localTripFilter;
    if (activeTripFilter != null) {
      return _memoryService.getMemoriesByTrip(activeTripFilter);
    }
    // Top-level: show only logged-in user's memories (to build folder view)
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

      String? selectedTrip = widget.filterTripName;
      if (selectedTrip == null && trips.isNotEmpty) {
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
      if (selectedTrip == null && trips.isNotEmpty && widget.filterTripName == null) return; // User cancelled

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
        if (!mounted) return;
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
      body: Stack(
        children: [
          // Background Depth Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kTeal.withValues(alpha: 0.05)),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 10.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: 200,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kTeal.withValues(alpha: 0.03)),
            ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 15.seconds, curve: Curves.easeInOut),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              FutureBuilder<List<MemoryModel>>(
                future: _memoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kTeal)));
                  }
                  final allMemories = snapshot.data ?? [];
                  
                  if (widget.filterTripName == null && _localTripFilter == null) {
                    // SHOW FOLDERS view
                    final Map<String, MemoryModel> tripFolders = {};
                    for (var m in allMemories) {
                       if (!tripFolders.containsKey(m.tripName)) {
                          tripFolders[m.tripName] = m;
                       }
                    }

                    if (tripFolders.isEmpty && !_isUploading) {
                       return SliverToBoxAdapter(
                         child: SizedBox(
                           height: MediaQuery.of(context).size.height * 0.5, 
                           child: _buildEmptyState(),
                         )
                       );
                    }

                    final names = tripFolders.keys.toList();
                    return SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final name = names[index];
                            return _buildFolderItem(name, tripFolders[name]!);
                          },
                          childCount: names.length,
                        ),
                      ),
                    );
                  } else {
                    // SHOW POLAROIDS logic 
                    final filteredMemories = _localTripFilter != null 
                        ? allMemories.where((m) => m.tripName == _localTripFilter).toList() 
                        : allMemories;

                    if (filteredMemories.isEmpty && !_isUploading) {
                       return SliverToBoxAdapter(
                         child: SizedBox(
                           height: MediaQuery.of(context).size.height * 0.5, 
                           child: _buildEmptyState(),
                         )
                       );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        itemBuilder: (context, index) => AnimatedCard(
                          index: index,
                          child: _memoryPolaroid(filteredMemories[index]),
                        ),
                        childCount: filteredMemories.length,
                      ),
                    );
                  }
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Lift above Dashboard's nav bar
        child: FloatingActionButton.extended(
          onPressed: () => _pickPhoto(ImageSource.gallery),
          backgroundColor: kTeal,
          label: _isUploading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Text('Add Memory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
          icon: _isUploading ? null : const Icon(Icons.add_a_photo_rounded, color: Colors.black),
        ),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildSliverAppBar() {
    final bool isNested = widget.filterTripName == null && _localTripFilter != null;
    final title = isNested ? _localTripFilter! : (widget.filterTripName ?? 'Memory Vault');
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: kSurface.withValues(alpha: 0.9),
      elevation: 0,
      leading: isNested 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
              onPressed: () {
                setState(() => _localTripFilter = null);
                _refreshMemories();
              },
            )
          : (Navigator.canPop(context) ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
            ) : null),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          title,
          style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -1),
        ),
        background: Stack(
          alignment: Alignment.centerRight,
          children: [
            Positioned(
              right: -20,
              top: 50,
              child: Opacity(
                opacity: 0.3,
                child: const Icon(Icons.camera_rounded, color: kTeal, size: 180),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kSurface.withValues(alpha: 0.3), kSurface],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderItem(String tripName, MemoryModel cover) {
    return GestureDetector(
      onTap: () {
        setState(() => _localTripFilter = tripName);
        _refreshMemories();
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _resolveImageUrl(cover.imageUrl),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: kWhite.withValues(alpha: 0.05),
                      child: const Center(child: Icon(Icons.broken_image_rounded, color: kTeal, size: 30)),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tripName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kWhite, fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Trip Album',
              style: TextStyle(color: kTeal.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImageUrl(String path) {
    final root = ApiConfig.baseUrl.replaceAll('/api', '');
    if (path.startsWith('http')) {
      // Fix old database entries that might have hardcoded localhost
      return path.replaceAll('http://localhost:3000', root);
    }
    return '$root/$path';
  }

  Widget _memoryPolaroid(MemoryModel memory) {
    return GestureDetector(
      onLongPress: () => _showImageOptions(memory),
      child: GlassContainer(
        padding: const EdgeInsets.all(8),
        radius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      _resolveImageUrl(memory.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.white12,
                        child: const Icon(Icons.broken_image_rounded, color: kTeal, size: 32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _showImageOptions(memory),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.more_vert_rounded, color: kWhite, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        memory.tripName.toUpperCase(),
                        style: const TextStyle(color: kTeal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      if (memory.uploaderName != null && memory.userId != _myId)
                        Text(
                          'by ${memory.uploaderName!.split(' ')[0]}',
                          style: TextStyle(color: kWhite.withValues(alpha: 0.2), fontSize: 8, fontWeight: FontWeight.w800),
                        ),
                    ],
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
      ),
    );
  }

  void _showImageOptions(MemoryModel memory) {
    if (memory.userId != _myId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This memory was shared by someone else. You can only manage your own uploads.', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            // Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _resolveImageUrl(memory.imageUrl),
                height: 120, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(height: 80, color: Colors.white12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              memory.tripName,
              style: const TextStyle(color: kTeal, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
            ),
            const SizedBox(height: 20),
            // DELETE
            _optionTile(
              icon: Icons.delete_forever_rounded,
              label: 'Delete Memory',
              color: const Color(0xFFFF5B5B),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMemory(memory);
              },
            ),
            const SizedBox(height: 12),
            // UPDATE
            _optionTile(
              icon: Icons.drive_file_move_rounded,
              label: 'Move to Another Trip',
              color: kTeal,
              onTap: () {
                Navigator.pop(ctx);
                _updateMemoryTrip(memory);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMemory(MemoryModel memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Memory?', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
        content: const Text('This photo will be permanently removed from the vault.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF5B5B), fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await _memoryService.deleteMemory(memory.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Memory deleted.' : 'Failed to delete. Try again.'),
      backgroundColor: ok ? const Color(0xFFFF5B5B) : Colors.red[900],
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) _refreshMemories();
  }

  Future<void> _updateMemoryTrip(MemoryModel memory) async {
    final userIdStr = await _authService.getUserId();
    if (userIdStr == null || !mounted) return;
    final userId = int.tryParse(userIdStr) ?? 0;
    final token = await _authService.getToken();
    final trips = await const TripService().getUserTrips(userId, token: token);
    if (!mounted) return;

    final selectedTrip = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Move to Trip', style: TextStyle(color: kWhite, fontWeight: FontWeight.w900)),
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
    if (selectedTrip == null || !mounted) return;
    final ok = await _memoryService.updateMemoryTripName(memory.id, selectedTrip);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Memory moved to "$selectedTrip".' : 'Failed to update. Try again.'),
      backgroundColor: ok ? kTeal : Colors.red[900],
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) _refreshMemories();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(40),
            radius: 40,
            child: Column(
              children: [
                const Icon(Icons.photo_library_rounded, color: kTeal, size: 80).animate().shake(delay: 500.ms).shimmer(duration: 2.seconds),
                const SizedBox(height: 24),
                const Text(
                  'The vault is empty.',
                  style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every great story starts with a single snap.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => _pickPhoto(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kTeal.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.add_a_photo_rounded, color: kTeal, size: 20),
            label: const Text('Snap a moment', style: TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 13)),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}
