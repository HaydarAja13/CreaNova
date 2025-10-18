import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/article_item.dart';

class ArticleService {
  static const String _baseUrl = 'https://well-pelican-real.ngrok-free.app/api/content';
  
  // Fallback static data jika API tidak tersedia
  static final List<ArticleItem> _fallbackArticles = [
    ArticleItem(
      id: '1',
      title: 'Cara Mudah Memilah Sampah di Rumah untuk Pemula',
      date: '15 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
      isNew: true,
      link: '/article/1',
    ),
    ArticleItem(
      id: '2',
      title: 'Manfaat Daur Ulang Plastik untuk Lingkungan',
      date: '12 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=400',
      isNew: true,
      link: '/article/2',
    ),
    ArticleItem(
      id: '3',
      title: 'Tips Mengurangi Sampah Plastik dalam Kehidupan Sehari-hari',
      date: '10 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      isNew: false,
      link: '/article/3',
    ),
    ArticleItem(
      id: '4',
      title: 'Inovasi Terbaru dalam Teknologi Daur Ulang Sampah',
      date: '8 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1569163139394-de4e4f43e4e3?w=400',
      isNew: false,
      link: '/article/4',
    ),
    ArticleItem(
      id: '5',
      title: 'Mengubah Sampah Organik Menjadi Kompos Berkualitas',
      date: '5 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
      isNew: false,
      link: '/article/5',
    ),
    ArticleItem(
      id: '6',
      title: 'Bank Sampah: Solusi Cerdas Mengelola Sampah Rumah Tangga',
      date: '3 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400',
      isNew: false,
      link: '/article/6',
    ),
    ArticleItem(
      id: '7',
      title: 'Dampak Positif Ekonomi Sirkular untuk Masa Depan',
      date: '1 Januari 2025',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1569163139394-de4e4f43e4e3?w=400',
      isNew: false,
      link: '/article/7',
    ),
    ArticleItem(
      id: '8',
      title: 'Cara Kreatif Mendaur Ulang Barang Bekas di Rumah',
      date: '28 Desember 2024',
      source: 'TukarIn',
      imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=400',
      isNew: false,
      link: '/article/8',
    ),
  ];

  static Future<List<ArticleItem>> _fetchFromAPI() async {
    try {
      debugPrint('Fetching articles from API: $_baseUrl');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('API Response Status: ${response.statusCode}');
      debugPrint('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        if (jsonData.isEmpty) {
          debugPrint('API returned empty array, using fallback data');
          return _fallbackArticles;
        }
        
        debugPrint('Successfully parsed ${jsonData.length} articles from API');
        
        final articles = <ArticleItem>[];
        for (int i = 0; i < jsonData.length; i++) {
          try {
            final article = ArticleItem.fromJson(jsonData[i]);
            articles.add(article);
            debugPrint('Successfully parsed article ${i + 1}: ${article.title}');
          } catch (e) {
            debugPrint('Error parsing article ${i + 1}: $e');
            debugPrint('Article data: ${jsonData[i]}');
          }
        }
        
        return articles.isNotEmpty ? articles : _fallbackArticles;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return _fallbackArticles;
      }
    } catch (e) {
      debugPrint('Error fetching articles from API: $e');
      return _fallbackArticles;
    }
  }

  // Get all articles
  static Future<List<ArticleItem>> getAllArticles() async {
    return await _fetchFromAPI();
  }

  // Search articles
  static Future<List<ArticleItem>> searchArticles(String query) async {
    if (query.isEmpty) {
      return getAllArticles();
    }
    
    final articles = await _fetchFromAPI();
    final lowercaseQuery = query.toLowerCase();
    
    return articles
        .where((article) => 
            article.title.toLowerCase().contains(lowercaseQuery) ||
            article.source.toLowerCase().contains(lowercaseQuery) ||
            (article.content?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }

  // Get article by ID
  static Future<ArticleItem?> getArticleById(String id) async {
    try {
      final articles = await _fetchFromAPI();
      return articles.firstWhere((article) => article.id == id);
    } catch (e) {
      debugPrint('Article with ID $id not found: $e');
      return null;
    }
  }

  // Get new articles
  static Future<List<ArticleItem>> getNewArticles() async {
    final articles = await _fetchFromAPI();
    return articles.where((article) => article.isNew).toList();
  }

  // Get articles by category (for future use)
  static Future<List<ArticleItem>> getArticlesByCategory(String category) async {
    final articles = await _fetchFromAPI();
    // For now, return all articles since we don't have categories yet
    // In the future, you can filter by category here
    return articles;
  }
}