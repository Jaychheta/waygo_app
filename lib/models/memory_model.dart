class MemoryModel {
  final String id;
  final String tripName;
  final String imageUrl;
  final DateTime date;

  const MemoryModel({
    required this.id,
    required this.tripName,
    required this.imageUrl,
    required this.date,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) => MemoryModel(
        id: json['id']?.toString() ?? '',
        tripName: json['trip_name'] ?? '',
        imageUrl: json['image_url'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      );
}
