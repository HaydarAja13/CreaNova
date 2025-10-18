import 'package:flutter/foundation.dart';

@immutable
class TrashCategory {
  final int id;
  final String categoryName;
  final int point;
  final int stock;
  final int totalBalance;
  final String status;
  final String? image;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrashCategory({
    required this.id,
    required this.categoryName,
    required this.point,
    required this.stock,
    required this.totalBalance,
    required this.status,
    this.image,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrashCategory.fromJson(Map<String, dynamic> json) {
    return TrashCategory(
      id: json['id'] as int,
      categoryName: json['category_name'] as String,
      point: json['point'] as int,
      stock: json['stock'] as int,
      totalBalance: json['total_balance'] as int,
      status: json['status'] as String,
      image: json['image'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category_name': categoryName,
    'point': point,
    'stock': stock,
    'total_balance': totalBalance,
    'status': status,
    'image': image,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  // Helper method to get formatted price
  String get formattedPrice => 'Rp $point /Kg';

  // Helper method to get placeholder image if no image available
  String get displayImageUrl => imageUrl ?? 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400';
}