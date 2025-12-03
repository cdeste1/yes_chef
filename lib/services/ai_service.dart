// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const _apiKey = 'YOUR_OPENAI_API_KEY';

  static Future<String> matchDish(String query) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": "You match dishes to Michelin recipes."},
          {"role": "user", "content": "Find a Michelin recipe similar to $query."}
        ]
      }),
    );
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
