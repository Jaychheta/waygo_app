class Activity {
  final String time;
  final String name;
  final String location;
  final String description;
  final double rating;
  final String imageUrl;
  final bool isPopular;

  const Activity({
    required this.time,
    required this.name,
    required this.location,
    required this.description,
    required this.rating,
    required this.imageUrl,
    this.isPopular = false,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        time: json['time']?.toString() ?? '',
        name: json['name']?.toString() ?? json['placeName']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
        imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
        isPopular: json['is_popular'] as bool? ?? json['isPopular'] as bool? ?? false,
      );
}

class DayPlan {
  final int day;
  final String theme;
  final List<Activity> activities;

  const DayPlan({required this.day, required this.theme, required this.activities});

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        day: (json['day'] as num?)?.toInt() ?? 0,
        theme: json['theme']?.toString() ?? json['title']?.toString() ?? '',
        activities: (json['activities'] as List<dynamic>? ??
                json['places'] as List<dynamic>? ??
                [])
            .map((a) => Activity.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
}

class ItineraryModel {
  final String location;
  final int days;
  final List<DayPlan> dayPlans;

  const ItineraryModel({
    required this.location,
    required this.days,
    required this.dayPlans,
  });

  factory ItineraryModel.fromJsonList(
    List<dynamic> jsonList, {
    required String location,
  }) =>
      ItineraryModel(
        location: location,
        days: jsonList.length,
        dayPlans: jsonList
            .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
