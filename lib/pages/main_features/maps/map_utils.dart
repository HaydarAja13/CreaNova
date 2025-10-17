// map_utils.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

String buildStaticMapUrl({
  required double lat,
  required double lng,
  required String apiKey,
  int zoom = 15,
  int width = 600,
  int height = 300,
  int scale = 2,
  String markerColor = 'red',
}) {
  final params = {
    'center': '$lat,$lng',
    'zoom': '$zoom',
    'size': '${width}x$height',
    'scale': '$scale',
    'maptype': 'roadmap',
    'markers': 'color:$markerColor|$lat,$lng',
    'key': apiKey,
  };
  final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  return 'https://maps.googleapis.com/maps/api/staticmap?$query';
}

/// Buka Google Maps (app jika tersedia) untuk navigasi
Future<void> openInMaps({required double lat, required double lng, String? label}) async {
  Uri? uri;

  if (!kIsWeb && Platform.isAndroid) {
    // Intent turn-by-turn
    uri = Uri.parse('google.navigation:q=$lat,$lng'); // fallback jika tak ada label
    if (!await canLaunchUrl(uri)) {
      // Fallback ke web
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    }
  } else if (!kIsWeb && Platform.isIOS) {
    // Apple Maps jika ingin: 'http://maps.apple.com/?ll=$lat,$lng&q=${Uri.encodeComponent(label ?? '')}'
    // gunakan Google Maps web universal:
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  } else {
    // Web / others
    uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
