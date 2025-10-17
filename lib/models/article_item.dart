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

  const ArticleItem({
    required this.id,
    required this.title,
    required this.date,
    required this.source,
    required this.imageUrl,
    this.isNew = false,
    this.link,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) => ArticleItem(
    id: json['id'] as String,
    title: json['title'] as String,
    date: json['date'] as String,
    source: json['source'] as String? ?? 'TukarIn',
    imageUrl: json['imageUrl'] as String,
    isNew: json['isNew'] as bool? ?? false,
    link: json['link'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'source': source,
    'imageUrl': imageUrl,
    'isNew': isNew,
    'link': link,
  };
}
