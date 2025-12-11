/// Service de classification des emails par règles basiques
/// Permet de trier les emails en catégories sans utiliser l'IA
class EmailClassifierService {
  // Domaines typiques de notifications (services, banques, confirmations)
  static const _notificationDomains = [
    'google.com',
    'googleplay.com',
    'stripe.com',
    'paypal.com',
    'amazon.com',
    'ebay.com',
    'aliexpress.com',
    'oney.fr',
    'boursobank.com',
    'labanquepostale.fr',
    'creditmutuel.fr',
    'bnpparibas.com',
    'societegenerale.fr',
    'lcl.fr',
    'caisse-epargne.fr',
    'apple.com',
    'microsoft.com',
    'facebook.com',
    'instagram.com',
    'twitter.com',
    'linkedin.com',
    'github.com',
    'gitlab.com',
    'airbnb.com',
    'booking.com',
    'uber.com',
    'deliveroo.fr',
    'ubereats.com',
    'sncf.com',
    'ratp.fr',
    'edf.fr',
    'orange.fr',
    'free.fr',
    'bouyguestelecom.fr',
    'sfr.fr',
  ];

  // Mots-clés dans le sujet pour les notifications
  static const _notificationKeywords = [
    'confirmation',
    'alerte',
    'notification',
    'rappel',
    'facture',
    'reçu',
    'paiement',
    'transaction',
    'virement',
    'prélèvement',
    'solde',
    'compte',
    'livraison',
    'commande',
    'réservation',
    'rendez-vous',
    'code',
    'vérification',
    'sécurité',
    'mot de passe',
    'connexion',
    'abonnement',
    'factures',
  ];

  // Domaines typiques de newsletters
  static const _newsletterDomains = [
    'marketing.',
    'newsletter.',
    'promo.',
    'news.',
    'mail.',
    'emails.',
    'campaigns.',
  ];

  // Mots-clés pour newsletters
  static const _newsletterKeywords = [
    'newsletter',
    'promotion',
    'offre',
    'deal',
    'soldes',
    'réduction',
    '% de réduction',
    'code promo',
    'exclusif',
    'nouveauté',
    'catalogue',
    'découvrir',
    'inscription',
    'désabonner',
    'unsubscribe',
    'se désinscrire',
    'publicité',
    'advertising',
  ];

  // Préfixes d'emails automatiques (souvent newsletters)
  static const _autoEmailPrefixes = [
    'noreply@',
    'no-reply@',
    'donotreply@',
    'ne-pas-repondre@',
    'info@',
    'contact@',
    'support@',
    'hello@',
    'bonjour@',
  ];

  /// Classifier un email en catégorie: 'personnel', 'notification', ou 'newsletter'
  String classifyEmail({
    required String from,
    required String subject,
    String? body,
  }) {
    final fromLower = from.toLowerCase();
    final subjectLower = subject.toLowerCase();
    final bodyLower = body?.toLowerCase() ?? '';

    // 1. Vérifier si c'est une NEWSLETTER
    if (_isNewsletter(fromLower, subjectLower, bodyLower)) {
      return 'newsletter';
    }

    // 2. Vérifier si c'est une NOTIFICATION
    if (_isNotification(fromLower, subjectLower, bodyLower)) {
      return 'notification';
    }

    // 3. Par défaut: PERSONNEL
    return 'personnel';
  }

  /// Déterminer l'importance d'un email: 'haute', 'moyenne', 'faible'
  String determineImportance({
    required String from,
    required String subject,
    String? body,
    String? category,
  }) {
    final subjectLower = subject.toLowerCase();
    final bodyLower = body?.toLowerCase() ?? '';

    // Mots-clés urgents
    final urgentKeywords = [
      'urgent',
      'important',
      'immédiat',
      'action requise',
      'attention',
      'alerte',
      'problème',
      'erreur',
      'échec',
      'facture',
      'paiement',
      'rappel',
      'dernier',
    ];

    // Si contient un mot-clé urgent → Haute importance
    for (final keyword in urgentKeywords) {
      if (subjectLower.contains(keyword) || bodyLower.contains(keyword)) {
        return 'haute';
      }
    }

    // Si c'est une newsletter → Faible importance
    if (category == 'newsletter') {
      return 'faible';
    }

    // Si c'est une notification → Moyenne importance
    if (category == 'notification') {
      return 'moyenne';
    }

    // Personnel → Haute importance par défaut
    return 'haute';
  }

  /// Générer un résumé court de l'email (sans IA)
  String generateBasicSummary({
    required String subject,
    String? body,
  }) {
    // Si le corps est court, on le retourne directement
    if (body != null && body.length < 100) {
      return body.trim();
    }

    // Sinon, prendre les 100 premiers caractères du corps
    if (body != null && body.isNotEmpty) {
      final cleaned = body.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.length > 100) {
        return '${cleaned.substring(0, 97)}...';
      }
      return cleaned;
    }

    // Si pas de corps, retourner le sujet
    return subject;
  }

  // --- Méthodes privées ---

  bool _isNewsletter(String from, String subject, String body) {
    // Vérifier les préfixes d'emails automatiques
    for (final prefix in _autoEmailPrefixes) {
      if (from.startsWith(prefix)) {
        // C'est probablement une newsletter, sauf si c'est une notification claire
        if (!_hasNotificationKeywords(subject, body)) {
          return true;
        }
      }
    }

    // Vérifier les domaines typiques de newsletters
    for (final domain in _newsletterDomains) {
      if (from.contains(domain)) {
        return true;
      }
    }

    // Vérifier les mots-clés de newsletter dans le sujet
    for (final keyword in _newsletterKeywords) {
      if (subject.contains(keyword) || body.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  bool _isNotification(String from, String subject, String body) {
    // Vérifier les domaines de services connus
    for (final domain in _notificationDomains) {
      if (from.contains(domain)) {
        return true;
      }
    }

    // Vérifier si le domaine contient "bank" ou "banque"
    if (from.contains('bank') || from.contains('banque')) {
      return true;
    }

    // Vérifier les mots-clés de notification
    if (_hasNotificationKeywords(subject, body)) {
      return true;
    }

    return false;
  }

  bool _hasNotificationKeywords(String subject, String body) {
    for (final keyword in _notificationKeywords) {
      if (subject.contains(keyword) || body.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
