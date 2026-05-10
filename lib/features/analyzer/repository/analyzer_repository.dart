import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/analysis_data.dart';

class AnalyzerRepository {
  static const _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<AnalysisData> analyzeImage(File imageFile, String language) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception('GROQ_API_KEY not set in .env');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
            'max_tokens': 1024,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:image/jpeg;base64,$base64Image',
                    },
                  },
                  {
                    'type': 'text',
                    'text': '''Analyze this image and return ONLY a JSON object with no extra text. 
IMPORTANT: The "description" and "label" fields MUST be in ${language == 'hi' ? 'Hindi' : 'English'}.
{
  "description": "brief overall description",
  "tags": [{"label": "object name", "confidence": 95}],
  "dominant_colors": ["color1", "color2"]
}''',
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
          error['error']?['message'] ?? 'API error ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content =
        data['choices'][0]['message']['content'] as String;

    final clean =
        content.replaceAll(RegExp(r'```json|```'), '').trim();
    final parsed = jsonDecode(clean) as Map<String, dynamic>;

    return AnalysisData.fromJson(parsed);
  }
}