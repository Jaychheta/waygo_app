class MemoryModel {
  final String id;
  final String userId;
  final String tripName;
  final String imageUrl;
  final DateTime date;
  final String? uploaderName;

  const MemoryModel({
    required this.id,
    required this.userId,
    required this.tripName,
    required this.imageUrl,
    required this.date,
    this.uploaderName,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) => MemoryModel(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        tripName: json['trip_name'] ?? '',
        imageUrl: json['image_url'] ?? '',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        uploaderName: json['uploader_name'],
      );
}
