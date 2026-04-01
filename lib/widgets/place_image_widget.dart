import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/place_image_service.dart';

class PlaceImageWidget extends StatefulWidget {
  final String placeName;
  final String cityName;
  final String category;
  final String description;

  const PlaceImageWidget({
    super.key,
    required this.placeName,
    required this.cityName,
    this.category = '',
    this.description = '',
  });

  @override
  State<PlaceImageWidget> createState() => _PlaceImageWidgetState();
}

class _PlaceImageWidgetState extends State<PlaceImageWidget> {
  String? _imageUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final url = await PlaceImageService.instance.fetchImage(
      placeName: widget.placeName,
      cityName: widget.cityName,
      category: widget.category,
      description: widget.description,
    );
    if (mounted) {
      setState(() {
        _imageUrl = url;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: kNavy3,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: kTeal),
          ),
        ),
      );
    }
    
    if (_imageUrl == null) {
      return Container(
        color: kNavy3,
        child: Icon(Icons.broken_image_outlined, color: kWhite.withValues(alpha: 0.1), size: 30),
      );
    }

    return Image.network(
      _imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Container(
        color: kNavy3,
        child: Icon(Icons.broken_image_outlined, color: kWhite.withValues(alpha: 0.1), size: 30),
      ),
    );
  }
}
