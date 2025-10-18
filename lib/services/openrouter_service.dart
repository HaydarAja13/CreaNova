import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKey =
      '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';
  
  // List of models to try in order (free models)
  static const List<String> _models = [
    'meta-llama/llama-3.2-3b-instruct:free',
    'microsoft/phi-3-mini-128k-instruct:free',
    'google/gemma-2-9b-it:free',
    'qwen/qwen-2-7b-instruct:free',
  ];

  static Future<String> sendMessage(
    String message,
    List<Map<String, String>> conversationHistory,
  ) async {
    // Prepare messages for the API
    List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content':
            'Kamu adalah asisten AI ramah yang berfokus pada isu lingkungan, khususnya pengelolaan sampah dan kebersihan. Tugasmu adalah memberikan informasi, solusi, serta edukasi seputar daur ulang, bank sampah, pemilahan sampah, pengelolaan limbah rumah tangga, dan gaya hidup ramah lingkungan. Gunakan bahasa Indonesia yang jelas, hangat, dan mudah dipahami oleh semua kalangan. Jawabanmu harus praktis, relevan, dan mendorong tindakan positif terhadap pelestarian lingkungan. Hindari menjawab hal di luar topik seperti politik, hiburan, atau hal yang tidak berkaitan dengan lingkungan dan pengelolaan sampah. Jika pengguna menanyakan sesuatu di luar topik tersebut, arahkan mereka dengan sopan kembali ke pembahasan tentang lingkungan, kebersihan, atau bank sampah.',
      },
    ];

    // Try each model until one works
    for (String model in _models) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://magyasaka-app.com',
            'X-Title': 'Magyasaka Chatbot',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'max_tokens': 500,
            'temperature': 0.7,
            'stream': false,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            return data['choices'][0]['message']['content'].toString().trim();
          }
        } else {
          // Log error but continue to next model
          debugPrint('Model $model failed: ${response.statusCode} - ${response.body}');
          continue;
        }
      } catch (e) {
        // Log error but continue to next model
        debugPrint('Model $model error: $e');
        continue;
      }
    }

    // If all models fail, return fallback message
    return 'Maaf, saya tidak dapat memproses permintaan Anda saat ini. Silakan coba lagi nanti.';
  }
}
