import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class PerplexityService {
  final SecureStorageService _secureStorage;

  // API Key chargée de manière asynchrone depuis le stockage sécurisé
  String? _apiKey;
  bool _apiKeyLoaded = false;

  final String _apiUrl = 'https://api.perplexity.ai/chat/completions';
  final String _model = 'sonar-pro'; // Modèle optimisé pour la recherche

  PerplexityService(this._secureStorage);

  /// Charge l'API Key depuis le stockage sécurisé (lazy loading).
  Future<void> _loadApiKey() async {
    if (_apiKeyLoaded) return; // Déjà chargée, skip

    print('🔐 Chargement de l\'API Key Perplexity depuis le stockage sécurisé...');
    try {
      _apiKey = await _secureStorage.getPerplexityApiKey();
      _apiKeyLoaded = true;
      print('✅ API Key Perplexity chargée depuis le stockage sécurisé');
    } catch (e) {
      print('❌ Erreur chargement API Key Perplexity: $e');
      rethrow;
    }
  }

  // Effectuer une recherche web ou une vérification
  Future<String> searchWeb(String query) async {
    // 0. Charger l'API Key si pas encore fait
    await _loadApiKey();

    if (_apiKey == null || _apiKey!.isEmpty) {
      return '❌ Clé API Perplexity manquante. Impossible d\'effectuer la recherche.';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un assistant de recherche précis et factuel. Réponds de manière concise.'
            },
            {
              'role': 'user',
              'content': query
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        print('❌ Erreur API Perplexity: ${response.statusCode} - ${response.body}');
        return 'Erreur lors de la recherche web (${response.statusCode}).';
      }

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } catch (e) {
      print('❌ Exception Perplexity: $e');
      return 'Erreur technique lors de la recherche web.';
    }
  }

  // Vérifier la réputation d'un expéditeur (domaine, arnaques connues)
  Future<String> checkSenderReputation(String email) async {
    final domain = email.split('@').last;
    final query = 'Est-ce que le domaine "$domain" ou l\'adresse "$email" est associé à du spam, du phishing ou des arnaques ? Donne une réponse courte et factuelle.';
    return searchWeb(query);
  }

  // Fact-checking d'une affirmation
  Future<String> factCheck(String statement) async {
    final query = 'Vérifie cette affirmation : "$statement". Est-ce vrai ou faux ? Cite tes sources si possible.';
    return searchWeb(query);
  }
}
