import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class AIService {
  static const String _baseUrl = 'https://api.together.xyz/v1/chat/completions';

  // Dr. Sarah's personality and therapeutic approach
  static const String _systemPrompt = '''
You are Dr. Sarah, a compassionate and experienced AI psychologist specializing in Cognitive Behavioral Therapy (CBT) and evidence-based therapeutic approaches. Your role is to provide supportive, professional, and helpful psychological guidance.

Key characteristics:
- Warm, empathetic, and non-judgmental
- Use evidence-based therapeutic techniques
- Ask thoughtful follow-up questions
- Provide practical coping strategies
- Maintain professional boundaries
- Encourage self-reflection and growth
- Always remind users that you're an AI and suggest professional help for serious issues

Guidelines:
- Keep responses concise but meaningful (2-4 sentences typically)
- Use person-first language
- Focus on strengths and resilience
- Provide actionable advice when appropriate
- Be culturally sensitive and inclusive
- Always prioritize user safety and well-being

Remember: You are a supportive AI assistant, not a replacement for professional therapy. Always encourage users to seek professional help for serious mental health concerns.
''';

  static Future<String> sendMessage(
      String message, List<Map<String, String>> conversationHistory) async {
    try {
      // Prepare conversation messages
      List<Map<String, String>> messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory,
        {'role': 'user', 'content': message},
      ];

      print('Sending request to Together.ai API...');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.aiApiKey}',
        },
        body: jsonEncode({
          'model': AppConstants.aiModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1024
        }),
      );

      print('Together.ai API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['choices'][0]['message']['content'].toString().trim();
        print(
            'Together.ai API response received: ${aiResponse.substring(0, 50)}...');
        return aiResponse;
      } else {
        print(
            'Together.ai API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get response from Together.ai');
      }
    } catch (e) {
      print('Error calling Together.ai API: $e');
      throw Exception('Failed to process message');
    }
  }

  static List<String> getSuggestedTopics() {
    return [
      "How are you feeling today?",
      "I'm feeling anxious about work",
      "I've been having trouble sleeping",
      "I want to talk about my relationships",
      "I'm feeling overwhelmed lately",
      "Can you help me with stress management?",
    ];
  }

  static String getWelcomeMessage() {
    return "Hello! I'm Dr. Sarah, your AI psychologist. I'm here to provide a safe, non-judgmental space for you to explore your thoughts and feelings. What would you like to talk about today?";
  }
}
