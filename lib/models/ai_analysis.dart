import 'dart:convert';

class AiAnalysis {
  final String resume;
  final String importance; // haute, moyenne, faible
  final String category;

  AiAnalysis({
    required this.resume,
    required this.importance,
    required this.category,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      resume: json['resume'] as String? ?? '',
      importance: json['importance'] as String? ?? 'moyenne',
      category: json['category'] as String? ?? 'autre',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resume': resume,
      'importance': importance,
      'category': category,
    };
  }

  static AiAnalysis fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return AiAnalysis.fromJson(json);
    } catch (e) {
      // En cas d'erreur, retourner une analyse par défaut
      return AiAnalysis(
        resume: 'Erreur d\'analyse',
        importance: 'moyenne',
        category: 'autre',
      );
    }
  }
}
