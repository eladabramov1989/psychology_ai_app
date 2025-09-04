import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class PsychologyAIModel implements AnalyzableModel {
  final String modelName;
  final String? _domain;
  final String? _field;
  final Map<String, dynamic> _properties;

  PsychologyAIModel({
    required this.modelName,
    String? domain,
    String? field,
    Map<String, dynamic>? properties,
  })  : _domain = domain,
        _field = field,
        _properties = properties ?? {
          'model_type': AppConstants.aiModel,
          'therapeutic_approach': AppConstants.aiPsychologistSpecialty,
          'ai_name': AppConstants.aiPsychologistName,
          'psychological_features': {
            'emotion_analysis': true,
            'behavioral_patterns': true,
            'cognitive_assessment': true,
            'personality_traits': ['openness', 'conscientiousness'],
            'mental_health_focus': 'general',
            'therapy_approach': 'cognitive_behavioral'
          },
          'session_config': {
            'max_duration': AppConstants.sessionDurationMinutes,
            'max_sessions_per_day': AppConstants.maxSessionsPerDay,
            'reminder_window': AppConstants.sessionReminderMinutes
          },
          'capabilities': [
            'empathetic_responses',
            'cognitive_restructuring',
            'mindfulness_techniques',
            'behavioral_interventions',
            'crisis_detection'
          ]
        };

  @override
  String? get domain => _domain ?? 'clinical_psychology';

  @override
  String? get field => _field ?? AppConstants.aiPsychologistSpecialty;

  @override
  Map<String, dynamic> get properties => _properties;

  bool get isConfiguredForTherapy =>
      properties.containsKey('psychological_features') &&
      properties.containsKey('therapeutic_approach');

  bool get isCrisisCapable =>
      (properties['capabilities'] as List<dynamic>?)?.contains('crisis_detection') ?? false;

  String get therapeuticApproach =>
      properties['therapeutic_approach'] as String? ?? AppConstants.aiPsychologistSpecialty;

  static PsychologyAIModel get defaultModel => PsychologyAIModel(
        modelName: AppConstants.aiPsychologistName,
        domain: 'clinical_psychology',
        field: AppConstants.aiPsychologistSpecialty,
      );
}


/// Interface for AI models that can be analyzed
abstract class AnalyzableModel {
  String? get domain;
  String? get field;
  Map<String, dynamic> get properties;
}

class ModelAnalyzer {
  /// Psychology-related keywords used for analysis
  static const List<String> _psychologyKeywords = [
    'emotion',
    'behavior',
    'cognition',
    'personality',
    'mental',
    'psychological',
    'therapy'
  ];

  /// Analyzes if a model is psychologically oriented based on its properties
  static Future<bool> isPsychologicallyOriented(AnalyzableModel model) async {
    // Run analysis in separate isolate for better performance
    return compute(_analyzeModel, model);
  }

  static bool _analyzeModel(AnalyzableModel model) {
    final modelProperties =
        model.properties.keys.map((key) => key.toLowerCase());

    final hasPsychologyProperties = _psychologyKeywords.any(
        (keyword) => modelProperties.any((prop) => prop.contains(keyword)));

    final primaryDomain = (model.domain ?? model.field ?? '').toLowerCase();
    final isPsychologyDomain =
        _psychologyKeywords.any((keyword) => primaryDomain.contains(keyword));

    return hasPsychologyProperties || isPsychologyDomain;
  }
}
