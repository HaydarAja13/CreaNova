import 'package:flutter/foundation.dart';
import 'bank_site.dart';

@immutable
class BankUser {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String createdAt;
  final String updatedAt;
  final String role;
  final String? bankAddress;
  final double? bankLat;
  final double? bankLng;
  final String? photoUrl;
  final String? avatarUrl;

  const BankUser({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.role,
    this.bankAddress,
    this.bankLat,
    this.bankLng,
    this.photoUrl,
    this.avatarUrl,
  });

  factory BankUser.fromJson(Map<String, dynamic> json) {
    return BankUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      role: json['role'] as String,
      bankAddress: json['bankAddress'] as String?,
      bankLat: (json['bankLat'] as num?)?.toDouble(),
      bankLng: (json['bankLng'] as num?)?.toDouble(),
      photoUrl: json['photoUrl'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'email_verified_at': emailVerifiedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'role': role,
    'bankAddress': bankAddress,
    'bankLat': bankLat,
    'bankLng': bankLng,
    'photoUrl': photoUrl,
    'avatar_url': avatarUrl,
  };

  // Check if this user is a bank (has bank data)
  bool get isBank => bankAddress != null && bankLat != null && bankLng != null;

  // Convert to BankSite for compatibility with existing code
  BankSite toBankSite() {
    return BankSite(
      name: name,
      address: bankAddress ?? 'Alamat tidak tersedia',
      hours: '08.00 - 17.00', // Default hours since not in API
      lat: bankLat ?? 0.0,
      lng: bankLng ?? 0.0,
      imageUrl:
          avatarUrl ??
          'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
    );
  }
}
