class Shoe {
  final String id;
  final String name;
  final String brand;
  final DateTime purchaseDate;
  final double totalMileage;
  final List<MileageEntry> mileageHistory;

  Shoe({
    required this.id,
    required this.name,
    required this.brand,
    required this.purchaseDate,
    required this.totalMileage,
    required this.mileageHistory,
  });

  factory Shoe.fromJson(Map<String, dynamic> json) {
    return Shoe(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      totalMileage: json['totalMileage'].toDouble(),
      mileageHistory: (json['mileageHistory'] as List)
          .map((e) => MileageEntry.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'purchaseDate': purchaseDate.toIso8601String(),
      'totalMileage': totalMileage,
      'mileageHistory': mileageHistory.map((e) => e.toJson()).toList(),
    };
  }

  Shoe copyWith({
    String? id,
    String? name,
    String? brand,
    DateTime? purchaseDate,
    double? totalMileage,
    List<MileageEntry>? mileageHistory,
  }) {
    return Shoe(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalMileage: totalMileage ?? this.totalMileage,
      mileageHistory: mileageHistory ?? this.mileageHistory,
    );
  }
}

class MileageEntry {
  final String id;
  final DateTime date;
  final double distance;
  final String? notes;

  MileageEntry({
    required this.id,
    required this.date,
    required this.distance,
    this.notes,
  });

  factory MileageEntry.fromJson(Map<String, dynamic> json) {
    return MileageEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      distance: json['distance'].toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'distance': distance,
      'notes': notes,
    };
  }
}