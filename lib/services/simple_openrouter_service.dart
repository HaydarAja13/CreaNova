import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SimpleOpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _apiKey = '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';

  // List of free models to try
  static const List<String> _freeModels = [
    'meta-llama/llama-3.2-3b-instruct:free',
    'microsoft/phi-3-mini-128k-instruct:free',
    'google/gemma-2-9b-it:free',
    'qwen/qwen-2-7b-instruct:free',
  ];

  static Future<String> sendMessage(String message, {String userName = 'Magyasaka'}) async {
    // Try each free model until one works
    for (String model in _freeModels) {
      try {
        debugPrint('Trying model: $model');
        
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
            'messages': [
              {
                'role': 'system',   
                'content': 'Kamu adalah asisten AI yang membantu dengan pertanyaan seputar pengelolaan sampah, lingkungan, dan kebersihan. Jawab dengan bahasa Indonesia yang ramah dan informatif. Berikan jawaban yang singkat dan praktis. Nama user adalah $userName, jadi kamu bisa menyapa dengan nama tersebut jika diperlukan.'
              },
              {
                'role': 'user',
                'content': message,
              }
            ],
          }),
        ).timeout(const Duration(seconds: 20));

        debugPrint('Model $model - Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            String result = data['choices'][0]['message']['content'].toString().trim();
            debugPrint('Success with model: $model');
            return result;
          }
        } else {
          debugPrint('Model $model failed: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('Model $model error: $e');
        continue; // Try next model
      }
    }
    
    // If all models fail
    return 'Maaf, saya tidak dapat memproses permintaan Anda saat ini. Silakan coba lagi nanti.';
  }
}