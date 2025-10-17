import 'package:cloud_firestore/cloud_firestore.dart';

class WasteItem {
  final String name;
  final double weightKg;   // perkiraan
  final int points;        // poin per item (untuk total)

  WasteItem({required this.name, required this.weightKg, required this.points});

  Map<String, dynamic> toMap() => {
    'name': name,
    'weightKg': weightKg,
    'points': points,
  };

  factory WasteItem.fromMap(Map<String, dynamic> m) => WasteItem(
    name: m['name'] ?? '',
    weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
    points: (m['points'] as num?)?.toInt() ?? 0,
  );
}

class PickupOrder {
  final String id;
  final String userId;
  final String userName;
  final String userAddress;
  final double userLat;
  final double userLng;

  final String bankName;
  final String bankAddress;
  final double bankLat;
  final double bankLng;

  final String? photoUrl;               // bukti foto (opsional)
  final String timeslot;                // contoh: “Jumat 8 Agustus 09.00–10.00”
  final List<WasteItem> items;
  final double totalWeight;
  final int totalPoints;
  final String status;                  // requested | assigned | on_route | arrived | delivered | confirmed
  final Timestamp createdAt;

  PickupOrder({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAddress,
    required this.userLat,
    required this.userLng,
    required this.bankName,
    required this.bankAddress,
    required this.bankLat,
    required this.bankLng,
    this.photoUrl,
    required this.timeslot,
    required this.items,
    required this.totalWeight,
    required this.totalPoints,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userName': userName,
    'userAddress': userAddress,
    'userLat': userLat,
    'userLng': userLng,
    'bankName': bankName,
    'bankAddress': bankAddress,
    'bankLat': bankLat,
    'bankLng': bankLng,
    'photoUrl': photoUrl,
    'timeslot': timeslot,
    'items': items.map((e) => e.toMap()).toList(),
    'totalWeight': totalWeight,
    'totalPoints': totalPoints,
    'status': status,
    'createdAt': createdAt,
  };
}
