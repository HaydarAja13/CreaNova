import '../models/article_item.dart';

class ArticleService {
  // Static data untuk sementara - bisa diganti dengan API call
  static final List<ArticleItem> _articles = [
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

  // Get all articles
  static Future<List<ArticleItem>> getAllArticles() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_articles);
  }

  // Search articles
  static Future<List<ArticleItem>> searchArticles(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (query.isEmpty) {
      return getAllArticles();
    }
    
    final lowercaseQuery = query.toLowerCase();
    return _articles
        .where((article) => 
            article.title.toLowerCase().contains(lowercaseQuery) ||
            article.source.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Get article by ID
  static Future<ArticleItem?> getArticleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      return _articles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get new articles
  static Future<List<ArticleItem>> getNewArticles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _articles.where((article) => article.isNew).toList();
  }

  // Get articles by category (for future use)
  static Future<List<ArticleItem>> getArticlesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // For now, return all articles since we don't have categories yet
    return _articles;
  }
}