class TripModel {
  final int id;
  final String name;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;
  final String? imageUrl;

  const TripModel({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    this.imageUrl,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? 'Expedition',
      location: json['location']?.toString() ?? 'Global',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      imageUrl: json['cover_image_url'] != null && json['cover_image_url'].toString().isNotEmpty
          ? json['cover_image_url'].toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
}
