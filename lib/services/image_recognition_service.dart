import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageRecognitionService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKey = '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';
  
  // Model yang mendukung vision
  static const String _model = 'google/gemini-2.0-flash-exp:free';

  static Future<Map<String, dynamic>?> identifyWaste(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://magyasaka-app.com',
          'X-Title': 'Magyasaka Waste Recognition',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Identifikasi jenis sampah dalam gambar ini. Berikan respons dalam format JSON dengan struktur berikut:
{
  "wasteType": "nama jenis sampah (contoh: Botol Plastik)",
  "category": "kategori sampah (organik/anorganik/B3)",
  "price": "harga per kg dalam format 'XX Pts/Kg'",
  "funFacts": [
    "fakta menarik 1",
    "fakta menarik 2",
    "fakta menarik 3",
    "fakta menarik 4",
    "fakta menarik 5"
  ],
  "confidence": "tingkat kepercayaan dalam persen (contoh: 95)"
}

Pastikan fun facts berisi informasi edukatif tentang dampak lingkungan, proses daur ulang, atau statistik menarik tentang jenis sampah tersebut.'''
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'].toString().trim();
          
          // Extract JSON from response
          final jsonStart = content.indexOf('{');
          final jsonEnd = content.lastIndexOf('}') + 1;
          
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonString = content.substring(jsonStart, jsonEnd);
            final result = jsonDecode(jsonString);
            return result;
          }
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Image recognition error: $e');
    }
    
    return null;
  }

  // Fallback data untuk testing
  static Map<String, dynamic> getFallbackResult() {
    final List<Map<String, dynamic>> sampleResults = [
      {
        "wasteType": "Botol Plastik",
        "category": "anorganik",
        "price": "50 Pts/Kg",
        "funFacts": [
          "Terbuat dari PET yang butuh 450 tahun untuk terurai.",
          "500 miliar botol diproduksi per tahun di dunia.",
          "90% botol dipakai sekali lalu dibuang.",
          "Sampah paling banyak ditemukan di laut."
        ],
        "confidence": "95"
      },
      {
        "wasteType": "Kaleng Aluminium",
        "category": "anorganik",
        "price": "120 Pts/Kg",
        "funFacts": [
          "Dapat didaur ulang 100% tanpa kehilangan kualitas.",
          "Menghemat 95% energi dibanding produksi baru.",
          "Bisa menjadi kaleng baru dalam 60 hari.",
          "Aluminium bisa didaur ulang selamanya."
        ],
        "confidence": "92"
      },
      {
        "wasteType": "Kertas Bekas",
        "category": "anorganik",
        "price": "30 Pts/Kg",
        "funFacts": [
          "1 ton kertas daur ulang menyelamatkan 17 pohon.",
          "Dapat didaur ulang hingga 5-7 kali.",
          "Menghemat 60% energi dan 50% air.",
          "Indonesia hasilkan 64 juta ton sampah kertas/tahun."
        ],
        "confidence": "88"
      }
    ];
    
    // Return random sample for variety
    final random = DateTime.now().millisecondsSinceEpoch % sampleResults.length;
    return sampleResults[random];
  }
}