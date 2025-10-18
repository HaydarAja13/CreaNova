import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/bank_user.dart';
import '../models/bank_site.dart';

class BankService {
  static const String _baseUrl = 'https://well-pelican-real.ngrok-free.app/api/users';
  
  // Fallback static data jika API tidak tersedia
  static final List<BankSite> _fallbackBanks = [
    const BankSite(
      name: 'BS. Omah Resik',
      address: 'Jl. Ulin Selatan VI No.114, Padangsari',
      hours: '09.00 - 16.00',
      lat: -7.0563,
      lng: 110.4390,
      imageUrl: 'https://picsum.photos/id/1011/800/600',
    ),
    const BankSite(
      name: 'BS. Tembalang',
      address: 'Jl. Pembangunan…',
      hours: '08.00 - 17.00',
      lat: -7.0580,
      lng: 110.4452,
      imageUrl: 'https://picsum.photos/id/1015/800/600',
    ),
  ];

  static Future<List<BankSite>> _fetchFromAPI() async {
    try {
      debugPrint('Fetching banks from API: $_baseUrl');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Bank API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        if (jsonData.isEmpty) {
          debugPrint('API returned empty array, using fallback data');
          return _fallbackBanks;
        }
        
        debugPrint('Successfully parsed ${jsonData.length} users from API');
        
        final banks = <BankSite>[];
        for (int i = 0; i < jsonData.length; i++) {
          try {
            final bankUser = BankUser.fromJson(jsonData[i]);
            // Only include users that are banks (have bank data)
            if (bankUser.isBank) {
              final bankSite = bankUser.toBankSite();
              banks.add(bankSite);
              debugPrint('Successfully parsed bank ${banks.length}: ${bankSite.name}');
            }
          } catch (e) {
            debugPrint('Error parsing user ${i + 1}: $e');
            debugPrint('User data: ${jsonData[i]}');
          }
        }
        
        debugPrint('Found ${banks.length} banks from ${jsonData.length} users');
        return banks.isNotEmpty ? banks : _fallbackBanks;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return _fallbackBanks;
      }
    } catch (e) {
      debugPrint('Error fetching banks from API: $e');
      return _fallbackBanks;
    }
  }

  // Get all banks
  static Future<List<BankSite>> getAllBanks() async {
    return await _fetchFromAPI();
  }

  // Search banks by name or address
  static Future<List<BankSite>> searchBanks(String query) async {
    if (query.isEmpty) {
      return getAllBanks();
    }
    
    final banks = await _fetchFromAPI();
    final lowercaseQuery = query.toLowerCase();
    
    return banks
        .where((bank) => 
            bank.name.toLowerCase().contains(lowercaseQuery) ||
            bank.address.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Get bank by name
  static Future<BankSite?> getBankByName(String name) async {
    try {
      final banks = await _fetchFromAPI();
      return banks.firstWhere((bank) => bank.name == name);
    } catch (e) {
      debugPrint('Bank with name $name not found: $e');
      return null;
    }
  }
}