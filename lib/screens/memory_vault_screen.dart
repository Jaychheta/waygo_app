import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waygo_app/config/app_theme.dart';

class MemoryVaultScreen extends StatefulWidget {
  const MemoryVaultScreen({super.key});

  @override
  State<MemoryVaultScreen> createState() => _MemoryVaultScreenState();
}

class _MemoryVaultScreenState extends State<MemoryVaultScreen> {
  final _picker = ImagePicker();

  // Local memories list – in production, load from API
  final List<Map<String, dynamic>> _memories = [];

  bool _isUploading = false;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;

      setState(() => _isUploading = true);

      // Simulate upload delay; replace with MemoryService.uploadMemory() for real backend
      await Future<void>.delayed(const Duration(milliseconds: 800));

      setState(() {
        _memories.insert(0, {
          'path': file.path,
          'tripName': 'My Trip',
          'date': DateTime.now(),
        });
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory saved! 📸'), backgroundColor: kTeal),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kNavy2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: kSlate.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              const Text('Add Memory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kWhite)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.photo_camera_rounded,
                      label: 'Camera',
                      onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _sourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: kNavy3,
          borderRadius: BorderRadius.circular(kRadius16),
          border: Border.all(color: kWhite.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: kTeal, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        title: const Text('Memory Vault', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kWhite)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('${_memories.length} photos', style: const TextStyle(color: kSlate, fontSize: 13)),
          ),
        ],
      ),
      body: _memories.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _memories.length,
              itemBuilder: (_, i) => _memoryCard(_memories[i]),
            ),
      floatingActionButton: _isUploading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: kTeal,
              child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2.5)),
            )
          : FloatingActionButton.extended(
              onPressed: _showSourceSheet,
              backgroundColor: kTeal,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: kWhite),
              label: const Text('Add Memory', style: TextStyle(color: kWhite, fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: kTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kTeal.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.photo_library_rounded, color: kTeal, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('No memories yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kWhite)),
            const SizedBox(height: 10),
            const Text(
              'Capture and save your travel moments.\nTap the button below to add your first memory!',
              textAlign: TextAlign.center,
              style: TextStyle(color: kSlate, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _showSourceSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(gradient: kTealGradient, borderRadius: BorderRadius.circular(kRadius),
                  boxShadow: [BoxShadow(color: kTeal.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))]),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: kWhite, size: 20),
                    SizedBox(width: 10),
                    Text('Add First Memory', style: TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memoryCard(Map<String, dynamic> memory) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (memory['path'] != null)
            Image.file(File(memory['path'] as String), fit: BoxFit.cover)
          else
            Container(color: kNavy2, child: const Icon(Icons.image_rounded, color: kSlate, size: 40)),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Trip name label
          Positioned(
            bottom: 12, left: 12, right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory['tripName'] as String? ?? 'Trip',
                  style: const TextStyle(color: kWhite, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: kSlate, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(memory['date'] as DateTime?),
                      style: const TextStyle(color: kSlate, fontSize: 10),
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

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]} ${d.year}';
  }
}
