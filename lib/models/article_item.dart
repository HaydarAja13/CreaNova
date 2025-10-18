// lib/models/article_item.dart
import 'package:flutter/foundation.dart';

@immutable
class ArticleItem {
  final String id;        // unik (untuk analytics/route)
  final String title;     // judul artikel
  final String date;      // "1 Agustus 2025" (atau format bebas)
  final String source;    // "TukarIn"
  final String imageUrl;  // URL gambar
  final bool isNew;       // tampilkan badge "Terbaru"
  final String? link;     // opsional: url internal/eksternal
  final String? content;  // konten artikel lengkap

  const ArticleItem({
    required this.id,
    required this.title,
    required this.date,
    required this.source,
    required this.imageUrl,
    this.isNew = false,
    this.link,
    this.content,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    // Handle the actual API response format
    final String id = json['id']?.toString() ?? '';
    final String title = json['title']?.toString() ?? '';
    final String content = json['text']?.toString() ?? json['content']?.toString() ?? '';
    final String imageUrl = json['image_url']?.toString() ?? 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=400';
    
    // Parse date from created_at
    String date = '';
    try {
      if (json['created_at'] != null) {
        final createdDate = DateTime.parse(json['created_at'].toString());
        date = '${createdDate.day} ${_getMonthName(createdDate.month)} ${createdDate.year}';
      } else {
        date = DateTime.now().toString().split(' ')[0];
      }
    } catch (e) {
      date = DateTime.now().toString().split(' ')[0];
    }
    
    // Determine if article is new (created within last 7 days)
    bool isNew = false;
    try {
      if (json['created_at'] != null) {
        final createdDate = DateTime.parse(json['created_at'].toString());
        final now = DateTime.now();
        final difference = now.difference(createdDate).inDays;
        isNew = difference <= 7;
      }
    } catch (e) {
      isNew = false;
    }

    // Get source from content_type or default to TukarIn
    String source = json['content_type']?.toString() ?? 'TukarIn';

    return ArticleItem(
      id: id,
      title: title,
      date: date,
      source: source,
      imageUrl: imageUrl,
      isNew: isNew,
      link: json['link']?.toString(),
      content: content,
    );
  }

  static String _getMonthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'source': source,
    'imageUrl': imageUrl,
    'isNew': isNew,
    'link': link,
    'content': content,
  };
}
