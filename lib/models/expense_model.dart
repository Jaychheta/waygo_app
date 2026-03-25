/// Safely parses [v] (num or String) to double, defaulting to 0.
double _safeAmount(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> splitAmong;
  final String category; // 'food' | 'transport' | 'stay' | 'other'
  final DateTime date;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitAmong,
    required this.category,
    required this.date,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        amount: _safeAmount(json['amount']),
        paidBy: json['paid_by'] ?? '',
        splitAmong: List<String>.from(json['split_among'] ?? []),
        category: json['category'] ?? 'other',
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'paid_by': paidBy,
        'split_among': splitAmong,
        'category': category,
        'date': date.toIso8601String(),
      };
}

class SettlementModel {
  final String from;
  final String to;
  final double amount;

  const SettlementModel({required this.from, required this.to, required this.amount});

  factory SettlementModel.fromJson(Map<String, dynamic> json) => SettlementModel(
        from: json['from'] ?? '',
        to: json['to'] ?? '',
        amount: _safeAmount(json['amount']),
      );
}
