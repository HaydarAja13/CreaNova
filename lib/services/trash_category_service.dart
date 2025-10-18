import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/trash_category.dart';

class TrashCategoryService {
  static const String _baseUrl = 'https://well-pelican-real.ngrok-free.app/api/trash-categories';
  
  // Fallback static data jika API tidak tersedia
  static final List<TrashCategory> _fallbackCategories = [
    TrashCategory(
      id: 1,
      categoryName: 'Botol Plastik',
      point: 50,
      stock: 100,
      totalBalance: 1000,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TrashCategory(
      id: 2,
      categoryName: 'Kardus',
      point: 75,
      stock: 200,
      totalBalance: 1500,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TrashCategory(
      id: 3,
      categoryName: 'Koran',
      point: 50,
      stock: 150,
      totalBalance: 800,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TrashCategory(
      id: 4,
      categoryName: 'Minyak Jelantah',
      point: 40,
      stock: 80,
      totalBalance: 600,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TrashCategory(
      id: 5,
      categoryName: 'Botol Kaca',
      point: 60,
      stock: 120,
      totalBalance: 900,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TrashCategory(
      id: 6,
      categoryName: 'Kaleng Besi',
      point: 75,
      stock: 90,
      totalBalance: 700,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    TrashCategory(
      id: 7,
      categoryName: 'Sampah Daun',
      point: 20,
      stock: 300,
      totalBalance: 400,
      status: 'T',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static Future<List<TrashCategory>> _fetchFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        if (jsonData.isEmpty) {
          debugPrint('API returned empty array, using fallback data');
          return _fallbackCategories;
        }
        
        return jsonData.map((json) => TrashCategory.fromJson(json)).toList();
      } else {
        debugPrint('API error: ${response.statusCode}');
        return _fallbackCategories;
      }
    } catch (e) {
      debugPrint('Error fetching trash categories from API: $e');
      return _fallbackCategories;
    }
  }

  // Get all trash categories
  static Future<List<TrashCategory>> getAllCategories() async {
    return await _fetchFromAPI();
  }

  // Search categories
  static Future<List<TrashCategory>> searchCategories(String query) async {
    if (query.isEmpty) {
      return getAllCategories();
    }
    
    final categories = await _fetchFromAPI();
    final lowercaseQuery = query.toLowerCase();
    
    return categories
        .where((category) => 
            category.categoryName.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Get category by ID
  static Future<TrashCategory?> getCategoryById(int id) async {
    try {
      final categories = await _fetchFromAPI();
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      debugPrint('Category with ID $id not found: $e');
      return null;
    }
  }

  // Get categories by status
  static Future<List<TrashCategory>> getCategoriesByStatus(String status) async {
    final categories = await _fetchFromAPI();
    return categories.where((category) => category.status == status).toList();
  }
}