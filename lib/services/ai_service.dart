import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_analysis.dart';
import 'secure_storage_service.dart';

class AiService {
  final SecureStorageService _secureStorage;

  // API Key chargée de manière asynchrone depuis le stockage sécurisé
  String? _apiKey;
  bool _apiKeyLoaded = false;

  final String _apiUrl = 'https://api.anthropic.com/v1/messages';
  final String _model = 'claude-sonnet-4-5-20250929'; // Claude Sonnet 4.5 pour analyse précise

  AiService(this._secureStorage);

  /// Charge l'API Key depuis le stockage sécurisé (lazy loading).
  Future<void> _loadApiKey() async {
    if (_apiKeyLoaded) return; // Déjà chargée, skip

    print('🔐 Chargement de l\'API Key Anthropic depuis le stockage sécurisé...');
    try {
      _apiKey = await _secureStorage.getAnthropicApiKey();
      _apiKeyLoaded = true;
      print('✅ API Key Anthropic chargée depuis le stockage sécurisé');
    } catch (e) {
      print('❌ Erreur chargement API Key Anthropic: $e');
      rethrow;
    }
  }

  // Analyser un email avec Claude
  Future<AiAnalysis> analyzeEmail({
    required String subject,
    required String body,
  }) async {
    // 0. Charger l'API Key si pas encore fait
    await _loadApiKey();

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('❌ ANTHROPIC_API_KEY non configurée');
    }

    try {
      // Préparer le prompt pour Claude
      final prompt = _buildAnalysisPrompt(subject, body);

      // Appeler l'API Anthropic
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 500,
          'temperature': 0.3,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        print('❌ Erreur API Anthropic: ${response.statusCode}');
        print('Body: ${response.body}');
        throw Exception('Erreur API: ${response.statusCode}');
      }

      // Parser la réponse
      final responseData = jsonDecode(response.body);
      final aiResponse = responseData['content'][0]['text'] as String;

      print('🤖 Réponse IA brute: $aiResponse');

      // Extraire le JSON de la réponse
      final analysis = _extractJsonFromResponse(aiResponse);

      print('✅ Analyse IA terminée: ${analysis.resume}');

      return analysis;
    } catch (e) {
      print('❌ Erreur analyse IA: $e');
      // Retourner une analyse par défaut en cas d'erreur
      return AiAnalysis(
        resume: 'Email: $subject',
        importance: 'moyenne',
        category: 'général',
      );
    }
  }

  // Construire le prompt pour l'analyse
  String _buildAnalysisPrompt(String subject, String body) {
    // Limiter la longueur du body pour économiser des tokens
    final limitedBody =
        body.length > 1500 ? '${body.substring(0, 1500)}...' : body;

    return '''Tu es un assistant IA spécialisé dans l'analyse d'emails.

Analyse cet email et retourne UNIQUEMENT un JSON valide avec cette structure exacte :
{
  "resume": "Un résumé court et clair du contenu (max 100 caractères)",
  "importance": "haute|moyenne|faible",
  "category": "personnel|notification|newsletter"
}

Critères de catégorie :
- personnel : emails d'amis, famille, collègues (conversations réelles)
- notification : reçus, mises à jour de statut, confirmations, alertes sécurité
- newsletter : promotions, actualités, offres commerciales, spam marketing

EMAIL À ANALYSER :

Sujet : $subject

Corps :
$limitedBody

Retourne UNIQUEMENT le JSON, sans explication ni texte additionnel.''';
  }

  // Extraire le JSON de la réponse de Claude
  AiAnalysis _extractJsonFromResponse(String response) {
    try {
      // Essayer de parser directement
      final json = jsonDecode(response.trim());
      return AiAnalysis.fromJson(json);
    } catch (e) {
      // Si échec, essayer d'extraire le JSON avec regex
      final jsonMatch = RegExp(r'\{[^}]*\}').firstMatch(response);
      if (jsonMatch != null) {
        try {
          final json = jsonDecode(jsonMatch.group(0)!);
          return AiAnalysis.fromJson(json);
        } catch (_) {}
      }

      // Si tout échoue, parser manuellement les champs
      return _manualParse(response);
    }
  }

  // Parser manuellement si le JSON n'est pas valide
  AiAnalysis _manualParse(String response) {
    String resume = 'Analyse non disponible';
    String importance = 'moyenne';
    String category = 'newsletter';

    final resumeMatch =
        RegExp(r'"resume"\s*:\s*"([^"]*)"').firstMatch(response);
    if (resumeMatch != null) {
      resume = resumeMatch.group(1) ?? resume;
    }

    final importanceMatch =
        RegExp(r'"importance"\s*:\s*"([^"]*)"').firstMatch(response);
    if (importanceMatch != null) {
      importance = importanceMatch.group(1) ?? importance;
    }

    final categoryMatch =
        RegExp(r'"category"\s*:\s*"([^"]*)"').firstMatch(response);
    if (categoryMatch != null) {
      category = categoryMatch.group(1) ?? category;
    }

    return AiAnalysis(
      resume: resume,
      importance: importance,
      category: category,
    );
  }

  // Analyser plusieurs emails en batch (avec limite pour éviter rate limit)
  Future<List<AiAnalysis>> analyzeEmailsBatch(
    List<Map<String, String>> emails, {
    int delayMs = 1000, // Délai entre chaque appel
  }) async {
    final analyses = <AiAnalysis>[];

    for (final email in emails) {
      try {
        final analysis = await analyzeEmail(
          subject: email['subject'] ?? '',
          body: email['body'] ?? '',
        );
        analyses.add(analysis);

        // Attendre avant le prochain appel pour éviter rate limiting
        if (emails.indexOf(email) < emails.length - 1) {
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e) {
        print('⚠️ Erreur analyse email "${email['subject']}": $e');
        // Ajouter une analyse par défaut
        analyses.add(AiAnalysis(
          resume: email['subject'] ?? 'Email',
          importance: 'moyenne',
          category: 'newsletter',
        ));
      }
    }

    return analyses;
  }
  // Générer un brouillon d'email
  Future<String> generateDraft({
    required String instruction,
    String tone = 'professionnel',
  }) async {
    final prompt = '''Tu es un assistant de rédaction d'emails expert.
Rédige un email complet (Sujet + Corps) basé sur l'instruction suivante.
Ton : $tone

Instruction : "$instruction"

Format de réponse attendu :
SUJET: [Le sujet de l'email]
CORPS:
[Le corps de l'email]

Ne mets pas de texte avant ou après.''';

    return _callClaude(prompt);
  }

  // Générer une réponse à un email
  Future<String> generateReply({
    required String originalBody,
    String? instruction,
    String tone = 'professionnel',
  }) async {
    final prompt = '''Tu es un assistant de rédaction d'emails expert.
Rédige une réponse à l'email ci-dessous.
Ton : $tone
${instruction != null ? 'Instruction supplémentaire : "$instruction"' : ''}

EMAIL ORIGINAL :
$originalBody

Format de réponse attendu :
[Le corps de la réponse uniquement]

Ne mets pas de texte avant ou après.''';

    return _callClaude(prompt);
  }

  // Méthode générique pour appeler Claude
  Future<String> _callClaude(String prompt) async {
    // 0. Charger l'API Key si pas encore fait
    await _loadApiKey();

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API Key manquante');
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1000,
          'temperature': 0.7, // Plus créatif pour la rédaction
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur API: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } catch (e) {
      print('❌ Erreur génération IA: $e');
      rethrow;
    }
  }
}
