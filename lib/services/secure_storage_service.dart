import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage sécurisé pour les credentials sensibles.
///
/// Utilise Android Keystore pour chiffrer les données au repos.
/// Les données sont stockées de manière persistante et sécurisée.
class SecureStorageService {
  // Instance singleton de FlutterSecureStorage
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Clés de stockage (constants)
  static const String _keyEmailAddress = 'EMAIL_ADDRESS';
  static const String _keyEmailPassword = 'EMAIL_PASSWORD';
  static const String _keyImapHost = 'IMAP_HOST';
  static const String _keyImapPort = 'IMAP_PORT';
  static const String _keySmtpHost = 'SMTP_HOST';
  static const String _keySmtpPort = 'SMTP_PORT';
  static const String _keyAnthropicApiKey = 'ANTHROPIC_API_KEY';
  static const String _keyPerplexityApiKey = 'PERPLEXITY_API_KEY';

  /// Écrit une donnée sensible dans le stockage sécurisé.
  ///
  /// [key] : Clé d'identification
  /// [value] : Valeur à stocker (sera chiffrée)
  Future<void> writeSecureData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print('🔐 Stockage sécurisé: Clé "$key" écrite avec succès');
    } catch (e) {
      print('❌ Erreur écriture stockage sécurisé ($key): $e');
      rethrow;
    }
  }

  /// Lit une donnée sensible depuis le stockage sécurisé.
  ///
  /// [key] : Clé d'identification
  /// Retourne null si la clé n'existe pas.
  Future<String?> readSecureData(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        print('🔐 Stockage sécurisé: Clé "$key" lue avec succès');
      } else {
        print('⚠️ Stockage sécurisé: Clé "$key" inexistante');
      }
      return value;
    } catch (e) {
      print('❌ Erreur lecture stockage sécurisé ($key): $e');
      rethrow;
    }
  }

  /// Supprime une donnée du stockage sécurisé.
  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
      print('🗑️ Stockage sécurisé: Clé "$key" supprimée');
    } catch (e) {
      print('❌ Erreur suppression stockage sécurisé ($key): $e');
      rethrow;
    }
  }

  /// Supprime TOUTES les données du stockage sécurisé.
  /// ⚠️ ATTENTION: Action irréversible!
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      print('🗑️ Stockage sécurisé: TOUTES les clés supprimées');
    } catch (e) {
      print('❌ Erreur suppression totale stockage sécurisé: $e');
      rethrow;
    }
  }

  // =========================================================================
  // GETTERS SPÉCIFIQUES POUR LES CREDENTIALS EMAIL
  // =========================================================================

  /// Récupère l'adresse email depuis le stockage sécurisé.
  Future<String> getEmailAddress() async {
    final value = await readSecureData(_keyEmailAddress);
    if (value == null || value.isEmpty) {
      throw Exception(
        '🔐 ERREUR SÉCURITÉ: Email address non trouvée dans le stockage sécurisé. '
        'Assurez-vous que la migration initiale a été effectuée.',
      );
    }
    return value;
  }

  /// Récupère le mot de passe IMAP depuis le stockage sécurisé.
  Future<String> getImapPassword() async {
    final value = await readSecureData(_keyEmailPassword);
    if (value == null || value.isEmpty) {
      throw Exception(
        '🔐 ERREUR SÉCURITÉ: Mot de passe IMAP non trouvé dans le stockage sécurisé. '
        'Assurez-vous que la migration initiale a été effectuée.',
      );
    }
    return value;
  }

  /// Récupère l'hôte IMAP depuis le stockage sécurisé.
  Future<String> getImapHost() async {
    final value = await readSecureData(_keyImapHost);
    return value ?? 'imap.laposte.net'; // Fallback par défaut
  }

  /// Récupère le port IMAP depuis le stockage sécurisé.
  Future<int> getImapPort() async {
    final value = await readSecureData(_keyImapPort);
    return value != null ? int.tryParse(value) ?? 993 : 993; // Fallback par défaut
  }

  /// Récupère l'hôte SMTP depuis le stockage sécurisé.
  Future<String> getSmtpHost() async {
    final value = await readSecureData(_keySmtpHost);
    return value ?? 'smtp.laposte.net'; // Fallback par défaut
  }

  /// Récupère le port SMTP depuis le stockage sécurisé.
  Future<int> getSmtpPort() async {
    final value = await readSecureData(_keySmtpPort);
    return value != null ? int.tryParse(value) ?? 465 : 465; // Fallback par défaut
  }

  // =========================================================================
  // GETTERS SPÉCIFIQUES POUR L'API ANTHROPIC
  // =========================================================================

  /// Récupère la clé API Anthropic depuis le stockage sécurisé.
  Future<String> getAnthropicApiKey() async {
    final value = await readSecureData(_keyAnthropicApiKey);
    if (value == null || value.isEmpty) {
      throw Exception(
        '🔐 ERREUR SÉCURITÉ: Clé API Anthropic non trouvée dans le stockage sécurisé. '
        'Assurez-vous que la migration initiale a été effectuée.',
      );
    }
    return value;
  }

  // =========================================================================
  // GETTERS SPÉCIFIQUES POUR L'API PERPLEXITY
  // =========================================================================

  /// Récupère la clé API Perplexity depuis le stockage sécurisé.
  Future<String> getPerplexityApiKey() async {
    final value = await readSecureData(_keyPerplexityApiKey);
    if (value == null || value.isEmpty) {
      throw Exception(
        '🔐 ERREUR SÉCURITÉ: Clé API Perplexity non trouvée dans le stockage sécurisé. '
        'Assurez-vous que la migration initiale a été effectuée.',
      );
    }
    return value;
  }

  // =========================================================================
  // MÉTHODES D'ÉCRITURE POUR LA MIGRATION INITIALE
  // =========================================================================

  /// Écrit les credentials email dans le stockage sécurisé (migration initiale).
  Future<void> migrateEmailCredentials({
    required String emailAddress,
    required String emailPassword,
    required String imapHost,
    required String imapPort,
    required String smtpHost,
    required String smtpPort,
  }) async {
    await writeSecureData(_keyEmailAddress, emailAddress);
    await writeSecureData(_keyEmailPassword, emailPassword);
    await writeSecureData(_keyImapHost, imapHost);
    await writeSecureData(_keyImapPort, imapPort);
    await writeSecureData(_keySmtpHost, smtpHost);
    await writeSecureData(_keySmtpPort, smtpPort);
    print('✅ Migration Email: Tous les credentials ont été migrés vers le stockage sécurisé');
  }

  /// Écrit la clé API Anthropic dans le stockage sécurisé (migration initiale).
  Future<void> migrateAnthropicApiKey(String apiKey) async {
    await writeSecureData(_keyAnthropicApiKey, apiKey);
    print('✅ Migration Anthropic: Clé API migrée vers le stockage sécurisé');
  }

  /// Écrit la clé API Perplexity dans le stockage sécurisé (migration initiale).
  Future<void> migratePerplexityApiKey(String apiKey) async {
    await writeSecureData(_keyPerplexityApiKey, apiKey);
    print('✅ Migration Perplexity: Clé API migrée vers le stockage sécurisé');
  }

  /// Vérifie si les credentials email existent déjà dans le stockage sécurisé.
  Future<bool> hasEmailCredentials() async {
    final email = await readSecureData(_keyEmailAddress);
    final password = await readSecureData(_keyEmailPassword);
    return email != null && password != null;
  }

  /// Vérifie si la clé API Anthropic existe déjà dans le stockage sécurisé.
  Future<bool> hasAnthropicApiKey() async {
    final apiKey = await readSecureData(_keyAnthropicApiKey);
    return apiKey != null;
  }

  /// Vérifie si la clé API Perplexity existe déjà dans le stockage sécurisé.
  Future<bool> hasPerplexityApiKey() async {
    final apiKey = await readSecureData(_keyPerplexityApiKey);
    return apiKey != null;
  }
}
