import 'package:cloud_firestore/cloud_firestore.dart';

class Tenant {
  final String id;
  final String name;
  final double rent;
  final double lastReading;
  final Timestamp lastReadingDate;
  final Timestamp createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.rent,
    required this.lastReading,
    required this.lastReadingDate,
    required this.createdAt,
  });

  factory Tenant.fromMap(String id, Map<String, dynamic> data) {
    return Tenant(
      id: id,
      name: data['name'] ?? '',
      rent: (data['rent'] ?? 0).toDouble(),
      lastReading: (data['lastReading'] ?? 0).toDouble(),
      lastReadingDate: data['lastReadingDate'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rent': rent,
      'lastReading': lastReading,
      'lastReadingDate': lastReadingDate,
      'createdAt': createdAt,
    };
  }
}

class Bill {
  final String id;
  final String tenantId;
  final String tenantName;
  final bool rentIncluded;
  final double lastReading;
  final Timestamp lastReadingDate;
  final double latestReading;
  final Timestamp latestReadingDate;
  final double unitsUsed;
  final double rate;
  final double electricityAmount;
  final double rentAmount;
  final double totalAmount;
  final Timestamp createdAt;

  Bill({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.rentIncluded,
    required this.lastReading,
    required this.lastReadingDate,
    required this.latestReading,
    required this.latestReadingDate,
    required this.unitsUsed,
    required this.rate,
    required this.electricityAmount,
    required this.rentAmount,
    required this.totalAmount,
    required this.createdAt,
  });

  factory Bill.fromMap(String id, Map<String, dynamic> data) {
    return Bill(
      id: id,
      tenantId: data['tenantId'] ?? '',
      tenantName: data['tenantName'] ?? '',
      rentIncluded: data['rentIncluded'] ?? false,
      lastReading: (data['lastReading'] ?? 0).toDouble(),
      lastReadingDate: data['lastReadingDate'] ?? Timestamp.now(),
      latestReading: (data['latestReading'] ?? 0).toDouble(),
      latestReadingDate: data['latestReadingDate'] ?? Timestamp.now(),
      unitsUsed: (data['unitsUsed'] ?? 0).toDouble(),
      rate: (data['rate'] ?? 0).toDouble(),
      electricityAmount: (data['electricityAmount'] ?? 0).toDouble(),
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'tenantName': tenantName,
      'rentIncluded': rentIncluded,
      'lastReading': lastReading,
      'lastReadingDate': lastReadingDate,
      'latestReading': latestReading,
      'latestReadingDate': latestReadingDate,
      'unitsUsed': unitsUsed,
      'rate': rate,
      'electricityAmount': electricityAmount,
      'rentAmount': rentAmount,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
    };
  }
}

class MilkDoc {
  final Map<String, List<double>> days;

  MilkDoc({required this.days});

  factory MilkDoc.fromMap(Map<String, dynamic> data) {
    final Map<String, List<double>> days = {};
    if (data['days'] != null) {
      (data['days'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          days[key] = value.map((e) => (e as num).toDouble()).toList();
        }
      });
    }
    return MilkDoc(days: days);
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days,
    };
  }
}

class GlobalSettings {
  final double electricityRate;
  final double milkRate;

  GlobalSettings({
    required this.electricityRate,
    required this.milkRate,
  });

  factory GlobalSettings.fromMap(Map<String, dynamic> data) {
    return GlobalSettings(
      electricityRate: (data['electricityRate'] ?? 0).toDouble(),
      milkRate: (data['milkRate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'electricityRate': electricityRate,
      'milkRate': milkRate,
    };
  }
}
