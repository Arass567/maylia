import 'dart:async';
import 'package:enough_mail/enough_mail.dart';
import '../models/email_model.dart';
import 'secure_storage_service.dart';

class EmailService {
  final SecureStorageService _secureStorage;

  ImapClient? _imapClient;
  SmtpClient? _smtpClient;
  Completer<void>? _imapConnectingCompleter;

  // Credentials chargés de manière asynchrone depuis le stockage sécurisé
  String? _email;
  String? _password;
  String? _imapHost;
  int? _imapPort;
  String? _smtpHost;
  int? _smtpPort;

  // Flag pour savoir si les credentials ont été chargés
  bool _credentialsLoaded = false;

  String? get userEmail => _email;

  EmailService(this._secureStorage);

  /// Charge les credentials depuis le stockage sécurisé (lazy loading).
  Future<void> _loadCredentials() async {
    if (_credentialsLoaded) return; // Déjà chargés, skip

    print('🔐 Chargement des credentials depuis le stockage sécurisé...');
    try {
      _email = await _secureStorage.getEmailAddress();
      _password = await _secureStorage.getImapPassword();
      _imapHost = await _secureStorage.getImapHost();
      _imapPort = await _secureStorage.getImapPort();
      _smtpHost = await _secureStorage.getSmtpHost();
      _smtpPort = await _secureStorage.getSmtpPort();

      _credentialsLoaded = true;
      print('✅ Credentials chargés depuis le stockage sécurisé');
    } catch (e) {
      print('❌ Erreur chargement credentials: $e');
      rethrow;
    }
  }

  // Connexion IMAP avec retry mechanism
  Future<void> connectImap({int maxRetries = 3}) async {
    // 0. Charger les credentials si pas encore fait
    await _loadCredentials();

    // 1. Si déjà connecté, on retourne direct
    if (_imapClient != null && _imapClient!.isLoggedIn) {
      return;
    }

    // 2. Si une connexion est en cours, on attend qu'elle finisse
    if (_imapConnectingCompleter != null) {
      return _imapConnectingCompleter!.future;
    }

    // 3. Sinon, on lance la connexion avec retry
    _imapConnectingCompleter = Completer<void>();

    int attempt = 0;
    Duration backoffDelay = const Duration(seconds: 2);

    while (attempt < maxRetries) {
      try {
        // Re-vérifier au cas où (double-check locking pattern)
        if (_imapClient != null && _imapClient!.isLoggedIn) {
          _imapConnectingCompleter!.complete();
          _imapConnectingCompleter = null;
          return;
        }

        attempt++;
        print('🔌 Connexion IMAP (tentative $attempt/$maxRetries)...');

        // Créer un nouveau client uniquement si nécessaire
        // On s'assure de déconnecter proprement l'ancien si il existe mais est clean
        if (_imapClient != null) {
          try {
            await _imapClient!.logout();
          } catch (_) {}
        }

        _imapClient = ImapClient(isLogEnabled: false);

        // Augmenter le timeout à 60 secondes
        await _imapClient!.connectToServer(
          _imapHost!,
          _imapPort!,
          isSecure: true,
        ).timeout(const Duration(seconds: 60));

        await _imapClient!.login(_email!, _password!)
            .timeout(const Duration(seconds: 30));

        print('✅ Connexion IMAP réussie');
        _imapConnectingCompleter!.complete();
        _imapConnectingCompleter = null;
        return;

      } catch (e) {
        print('❌ Erreur connexion IMAP (tentative $attempt/$maxRetries): $e');

        if (attempt >= maxRetries) {
          _imapConnectingCompleter!.completeError(e);
          _imapConnectingCompleter = null;
          _imapClient = null; // Reset client on final error
          rethrow;
        }

        // Exponential backoff: attendre avant le prochain essai
        print('⏳ Retry dans ${backoffDelay.inSeconds}s...');
        await Future.delayed(backoffDelay);
        backoffDelay *= 2; // Double le délai pour chaque retry

        _imapClient = null; // Reset client avant retry
      }
    }
  }

  // Connexion SMTP
  Future<void> connectSmtp() async {
    // 0. Charger les credentials si pas encore fait
    await _loadCredentials();

    if (_smtpClient != null && _smtpClient!.isLoggedIn) {
      return;
    }

    _smtpClient = SmtpClient('smart_mail', isLogEnabled: false);

    try {
      await _smtpClient!.connectToServer(
        _smtpHost!,
        _smtpPort!,
        isSecure: true,
      );

      await _smtpClient!.ehlo();

      // Utiliser authenticate au lieu de login pour enough_mail 2.x
      await _smtpClient!.authenticate(_email!, _password!, AuthMechanism.plain);
      print('✅ Connexion SMTP réussie');
    } catch (e) {
      print('❌ Erreur connexion SMTP: $e');
      rethrow;
    }
  }

  // Récupérer la liste de tous les dossiers IMAP (avec récursion complète)
  Future<List<Mailbox>> getMailboxes() async {
    print('🚀 START: getMailboxes() - Scan récursif complet');
    await connectImap();

    try {
      // STRATÉGIE 1: Essayer avec wildcard "*" pour récursion automatique
      print('📞 Tentative 1: listMailboxes avec wildcard "*"...');
      final mailboxes = await _imapClient!.listMailboxes(
        path: '*',
      ).timeout(const Duration(seconds: 60));

      print('📂 ${mailboxes.length} dossiers récupérés (avec wildcard):');

      if (mailboxes.isNotEmpty) {
        // Filtrer les dossiers système non sélectionnables
        final filteredMailboxes = _filterSystemMailboxes(mailboxes);

        for (var m in filteredMailboxes) {
          print(' ✓ Name: ${m.name}, Path: ${m.path}, Flags: ${m.flags}');
        }

        return filteredMailboxes;
      }

      // STRATÉGIE 2: Si wildcard ne fonctionne pas, scan récursif manuel
      print('⚠️ Wildcard retourne 0 dossiers, passage au scan récursif manuel...');
      final allMailboxes = await _getAllMailboxesRecursive('');

      final filteredMailboxes = _filterSystemMailboxes(allMailboxes);
      print('📂 ${filteredMailboxes.length} dossiers récupérés (scan récursif):');

      for (var m in filteredMailboxes) {
        print(' ✓ Name: ${m.name}, Path: ${m.path}');
      }

      return filteredMailboxes;
    } catch (e) {
      print('❌ Erreur récupération dossiers: $e');
      rethrow;
    }
  }

  // Helper: Scan récursif manuel des dossiers IMAP
  Future<List<Mailbox>> _getAllMailboxesRecursive(String parentPath) async {
    final List<Mailbox> allMailboxes = [];

    try {
      // Récupérer les enfants directs du path parent
      final children = await _imapClient!.listMailboxes(
        path: parentPath.isEmpty ? '%' : '$parentPath/%',
      ).timeout(const Duration(seconds: 60));

      for (final mailbox in children) {
        allMailboxes.add(mailbox);

        // Scanner récursivement les sous-dossiers (sauf si noSelect)
        if (!mailbox.flags.contains(MailboxFlag.noSelect)) {
          try {
            final subMailboxes = await _getAllMailboxesRecursive(mailbox.path);
            allMailboxes.addAll(subMailboxes);
          } catch (e) {
            print('⚠️ Erreur scan sous-dossiers de ${mailbox.path}: $e');
            // Continuer même si un sous-dossier échoue
          }
        }
      }
    } catch (e) {
      print('⚠️ Erreur scan récursif pour path "$parentPath": $e');
    }

    return allMailboxes;
  }

  // Helper: Filtrer les dossiers système non accessibles
  List<Mailbox> _filterSystemMailboxes(List<Mailbox> mailboxes) {
    return mailboxes.where((mailbox) {
      // Exclure les dossiers noSelect (non sélectionnables)
      if (mailbox.flags.contains(MailboxFlag.noSelect)) {
        return false;
      }

      // Exclure les dossiers système Gmail/Google
      final lowerName = mailbox.name.toLowerCase();
      final lowerPath = mailbox.path.toLowerCase();

      if (lowerName.startsWith('[gmail]') ||
          lowerPath.startsWith('[gmail]') ||
          lowerName.startsWith('[google') ||
          lowerPath.startsWith('[google')) {
        return false;
      }

      // Exclure les dossiers cachés commençant par "."
      if (mailbox.name.startsWith('.') && mailbox.name != '.') {
        return false;
      }

      return true;
    }).toList();
  }

  // Sélectionner un dossier spécifique
  Future<Mailbox> selectMailbox(String path) async {
    await connectImap();

    try {
      final mailbox = await _imapClient!.selectMailboxByPath(path);
      print('✅ Dossier sélectionné: $path');
      return mailbox;
    } catch (e) {
      print('❌ Erreur sélection dossier $path: $e');
      rethrow;
    }
  }

  // Récupérer les emails d'un dossier spécifique (MODE RAPIDE - 30 derniers)
  Future<List<EmailModel>> fetchEmailsFromMailbox(
    String mailboxPath, {
    int? limit, // Par défaut 30, null = TOUS (attention!)
  }) async {
    await connectImap();

    try {
      // 🔍 DIAGNOSTIC: Début du fetch
      print('');
      print('🔍 ======================================');
      print('🔍 DIAGNOSTIC IMAP: Début du fetch...');
      print('🔍 Dossier: $mailboxPath');
      print('🔍 Limite demandée: ${limit ?? "TOUS"}');
      print('🔍 ======================================');
      print('');

      // ÉTAPE 1: Sélectionner le dossier
      print('📂 Sélection du dossier: $mailboxPath');
      final mailboxInfo = await _imapClient!.selectMailboxByPath(mailboxPath);

      // ÉTAPE 2: Compter les messages
      final total = mailboxInfo.messagesExists;
      print('📊 Total messages dans $mailboxPath: $total');

      // Si vide, retour immédiat
      if (total == 0) {
        print('📭 Dossier vide');
        print('🔍 FIN DIAGNOSTIC: 0 messages, aucune conversion nécessaire.');
        return [];
      }

      // ÉTAPE 3: Calculer la plage (30 DERNIERS par défaut)
      final fetchLimit = limit ?? 30; // Par défaut: 30 derniers
      final from = total > fetchLimit ? (total - fetchLimit + 1) : 1;
      final to = total;

      print('📥 Récupération messages $from:$to (${to - from + 1} messages)');

      // ÉTAPE 4: FETCH ULTRA-LÉGER (UID + FLAGS + ENVELOPE)
      // ✅ IMPORTANT: Inclure UID pour identifier les emails!
      final fetchResult = await _imapClient!.fetchMessages(
        MessageSequence.fromRange(from, to),
        '(UID FLAGS ENVELOPE)',  // ✅ UID pour identifier les emails
      ).timeout(const Duration(seconds: 30)); // Timeout court: 30s

      // 🔍 DIAGNOSTIC: Messages bruts reçus
      print('');
      print('🔍 DIAGNOSTIC IMAP: Reçu ${fetchResult.messages.length} messages bruts du serveur.');
      print('');

      // ÉTAPE 5: Parser rapidement AVEC DIAGNOSTIC DÉTAILLÉ
      final emails = <EmailModel>[];
      int successCount = 0;
      int errorCount = 0;
      int noEnvelopeCount = 0;

      for (int i = 0; i < fetchResult.messages.length; i++) {
        final message = fetchResult.messages[i];
        final msgNumber = i + 1;
        final uid = message.uid ?? 0;

        // 🔍 DIAGNOSTIC: Vérifier si l'envelope existe
        final hasEnvelope = message.envelope != null;

        print('👉 Msg #$msgNumber: UID=$uid, HasEnvelope=$hasEnvelope. Tentative de conversion...');

        // Si pas d'envelope, skip mais compter
        if (!hasEnvelope) {
          print('   ⚠️ IGNORÉ CAR PAS D\'ENVELOPPE.');
          noEnvelopeCount++;
          continue;
        }

        try {
          final email = _parseEmailToModelLightweight(message);
          email.mailboxPath = mailboxPath;
          emails.add(email);
          successCount++;
          print('   ✅ Succès.');
        } catch (e, stackTrace) {
          errorCount++;
          print('   ❌ ERREUR: $e');
          print('   📍 StackTrace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
        }
      }

      // 🔍 DIAGNOSTIC: Résumé final
      print('');
      print('📊 ============================================');
      print('📊 FIN DIAGNOSTIC:');
      print('📊   - Messages bruts reçus: ${fetchResult.messages.length}');
      print('📊   - Convertis avec succès: $successCount');
      print('📊   - Erreurs de conversion: $errorCount');
      print('📊   - Ignorés (pas d\'enveloppe): $noEnvelopeCount');
      print('📊   - Total sauvegardé: ${emails.length}');
      print('📊 ============================================');
      print('');

      return emails;

    } catch (e) {
      print('❌ Erreur récupération $mailboxPath: $e');
      rethrow;
    }
  }

  // Déplacer un email vers un autre dossier
  Future<void> moveEmail(int uid, String sourceFolderPath, String targetFolderPath) async {
    await connectImap();

    try {
      // Sélectionner le dossier source
      await _imapClient!.selectMailboxByPath(sourceFolderPath);

      // Copier vers le dossier cible
      await _imapClient!.copy(
        MessageSequence.fromId(uid),
        targetMailboxPath: targetFolderPath,
      );

      // Supprimer l'original
      await deleteEmail(uid, sourceFolderPath);

      print('📦 Email UID $uid déplacé de $sourceFolderPath vers $targetFolderPath');
    } catch (e) {
      print('❌ Erreur déplacement email: $e');
      rethrow;
    }
  }

  // Récupérer les nouveaux emails (non lus)
  Future<List<EmailModel>> fetchNewEmails({int limit = 20, String mailboxPath = 'INBOX'}) async {
    await connectImap();

    try {
      // Sélectionner le dossier
      if (mailboxPath == 'INBOX') {
        await _imapClient!.selectInbox();
      } else {
        await selectMailbox(mailboxPath);
      }

      // Rechercher les emails non lus
      final searchResult = await _imapClient!.searchMessages(
        searchCriteria: 'UNSEEN',
      );

      if (searchResult.matchingSequence == null ||
          searchResult.matchingSequence!.isEmpty) {
        print('📭 Aucun nouveau mail');
        return [];
      }

      // Limiter le nombre de mails
      final ids = searchResult.matchingSequence!.toList();
      final idsToFetch = ids.length > limit ? ids.sublist(0, limit) : ids;

      // Récupérer les détails des emails
      final fetchResult = await _imapClient!.fetchMessages(
        MessageSequence.fromIds(idsToFetch),
        '(BODY.PEEK[] FLAGS)',
      );

      final emails = <EmailModel>[];

      for (final message in fetchResult.messages) {
        try {
          final email = _parseEmailToModel(message);
          email.mailboxPath = mailboxPath; // Ajouter le dossier
          emails.add(email);
        } catch (e) {
          print('⚠️ Erreur parsing email UID ${message.uid}: $e');
        }
      }

      print('📬 ${emails.length} nouveaux emails récupérés');
      return emails;
    } catch (e) {
      print('❌ Erreur récupération emails: $e');
      rethrow;
    }
  }

  // Récupérer tous les emails (limite)
  Future<List<EmailModel>> fetchAllEmails({int limit = 50, String mailboxPath = 'INBOX'}) async {
    await connectImap();

    try {
      // ✅ FIX: Sélectionner le BON dossier
      if (mailboxPath == 'INBOX') {
        await _imapClient!.selectInbox();
      } else {
        await selectMailbox(mailboxPath);
      }

      // Récupérer les derniers emails
      final fetchResult = await _imapClient!.fetchRecentMessages(
        messageCount: limit,
        criteria: '(BODY.PEEK[] FLAGS)',
      );

      final emails = <EmailModel>[];

      for (final message in fetchResult.messages) {
        try {
          final email = _parseEmailToModel(message);
          email.mailboxPath = mailboxPath; // Ajouter le dossier
          emails.add(email);
        } catch (e) {
          print('⚠️ Erreur parsing email UID ${message.uid}: $e');
        }
      }

      print('📬 ${emails.length} emails récupérés depuis $mailboxPath');
      return emails;
    } catch (e) {
      print('❌ Erreur récupération emails depuis $mailboxPath: $e');
      rethrow;
    }
  }

  // Parser un MimeMessage COMPLET en EmailModel (avec corps)
  EmailModel _parseEmailToModel(MimeMessage message) {
    final from = message.from?.toString() ?? 'Expéditeur inconnu';
    final to = message.to?.toString() ?? '';
    final subject = message.decodeSubject() ?? '(Pas de sujet)';
    final date = message.decodeDate() ?? DateTime.now();
    final isRead = message.isSeen;
    final hasAttachments = message.hasAttachments();

    // Récupérer le corps du mail
    String body = '';
    String bodyHtml = '';

    if (message.decodeTextPlainPart() != null) {
      body = message.decodeTextPlainPart() ?? '';
    }

    if (message.decodeTextHtmlPart() != null) {
      bodyHtml = message.decodeTextHtmlPart() ?? '';
    }

    // Si pas de texte brut mais HTML, utiliser HTML comme body
    if (body.isEmpty && bodyHtml.isNotEmpty) {
      body = _stripHtmlTags(bodyHtml);
    }

    return EmailModel.create(
      uid: message.uid ?? 0,
      from: from,
      to: to,
      subject: subject,
      body: body,
      bodyHtml: bodyHtml,
      date: date,
      isRead: isRead,
      hasAttachments: hasAttachments,
    );
  }

  // Parser un MimeMessage LÉGER en EmailModel (SANS corps - juste metadata)
  // Utilisé pour la synchronisation massive rapide
  EmailModel _parseEmailToModelLightweight(MimeMessage message) {
    final from = message.from?.toString() ?? 'Expéditeur inconnu';
    final to = message.to?.toString() ?? '';
    final subject = message.decodeSubject() ?? '(Pas de sujet)';
    final date = message.decodeDate() ?? DateTime.now();
    final isRead = message.isSeen;

    // Vérifier si le message a des pièces jointes via bodyStructure
    bool hasAttachments = false;
    if (message.body != null) {
      hasAttachments = message.hasAttachments();
    }

    // 🔥 Corps vide - sera téléchargé à la demande plus tard
    const String body = '[Corps non téléchargé - Cliquez pour charger]';
    const String bodyHtml = '';

    return EmailModel.create(
      uid: message.uid ?? 0,
      from: from,
      to: to,
      subject: subject,
      body: body,
      bodyHtml: bodyHtml,
      date: date,
      isRead: isRead,
      hasAttachments: hasAttachments,
    );
  }

  // Supprimer un email (VRAIMENT - avec EXPUNGE)
  Future<void> deleteEmail(int uid, String mailboxPath) async {
    await connectImap();

    try {
      // ✅ Sélectionner le BON dossier où se trouve l'email
      await _imapClient!.selectMailboxByPath(mailboxPath);

      print('🗑️ Tentative suppression email UID $uid de $mailboxPath...');

      // ⚡ IMPORTANT: Utiliser uidStore au lieu de store pour travailler avec les UIDs
      final storeResult = await _imapClient!.uidStore(
        MessageSequence.fromId(uid),
        [r'\Deleted'],
        action: StoreAction.add,
      );

      print('✓ Email marqué comme \\Deleted: ${storeResult != null}');

      // EXPUNGE pour supprimer définitivement
      await _imapClient!.expunge();

      print('✅ Email UID $uid supprimé définitivement de $mailboxPath');
    } catch (e) {
      print('❌ Erreur suppression email UID $uid de $mailboxPath: $e');
      rethrow;
    }
  }

  // Marquer comme lu
  Future<void> markAsRead(int uid, String mailboxPath) async {
    await connectImap();

    try {
      // ✅ Sélectionner le BON dossier où se trouve l'email
      await _imapClient!.selectMailboxByPath(mailboxPath);

      // ⚡ Utiliser uidStore pour travailler avec les UIDs
      await _imapClient!.uidStore(
        MessageSequence.fromId(uid),
        [r'\Seen'],
        action: StoreAction.add,
      );

      print('✅ Email UID $uid marqué comme lu dans $mailboxPath');
    } catch (e) {
      print('❌ Erreur marquage lu UID $uid dans $mailboxPath: $e');
      rethrow;
    }
  }

  // Marquer comme NON lu
  Future<void> markAsUnread(int uid, String mailboxPath) async {
    await connectImap();

    try {
      // ✅ Sélectionner le BON dossier où se trouve l'email
      await _imapClient!.selectMailboxByPath(mailboxPath);

      // ⚡ Utiliser uidStore pour travailler avec les UIDs
      await _imapClient!.uidStore(
        MessageSequence.fromId(uid),
        [r'\Seen'],
        action: StoreAction.remove,
      );

      print('✅ Email UID $uid marqué comme NON lu dans $mailboxPath');
    } catch (e) {
      print('❌ Erreur marquage non lu UID $uid dans $mailboxPath: $e');
      rethrow;
    }
  }

  // Envoyer un email
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? inReplyTo,
  }) async {
    await connectSmtp();

    try {
      final messageBuilder = MessageBuilder.prepareMultipartAlternativeMessage()
        ..from = [MailAddress('', _email!)]
        ..to = [MailAddress('', to)]
        ..subject = subject
        ..addTextPlain(body);

      if (inReplyTo != null) {
        messageBuilder.setHeader('In-Reply-To', inReplyTo);
      }

      final mimeMessage = messageBuilder.buildMimeMessage();

      await _smtpClient!.sendMessage(mimeMessage);

      print('📤 Email envoyé à $to');
    } catch (e) {
      print('❌ Erreur envoi email: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> disconnect() async {
    if (_imapClient != null && _imapClient!.isLoggedIn) {
      await _imapClient!.logout();
    }
    if (_smtpClient != null && _smtpClient!.isLoggedIn) {
      await _smtpClient!.quit();
    }
    print('👋 Déconnexion email services');
  }

  // Créer un nouveau dossier IMAP
  Future<void> createMailbox(String mailboxName) async {
    await connectImap();

    try {
      await _imapClient!.createMailbox(mailboxName);
      print('📁 Dossier créé: $mailboxName');
    } catch (e) {
      print('❌ Erreur création dossier $mailboxName: $e');
      rethrow;
    }
  }

  // Renommer un dossier IMAP
  Future<void> renameMailbox(String oldPath, String newPath) async {
    await connectImap();

    try {
      // Récupérer l'objet Mailbox
      final mailbox = await _imapClient!.selectMailboxByPath(oldPath);
      await _imapClient!.renameMailbox(mailbox, newPath);
      print('✏️ Dossier renommé: $oldPath → $newPath');
    } catch (e) {
      print('❌ Erreur renommage dossier $oldPath → $newPath: $e');
      rethrow;
    }
  }

  // Supprimer un dossier IMAP
  Future<void> deleteMailbox(String mailboxPath) async {
    await connectImap();

    try {
      // Récupérer l'objet Mailbox
      final mailbox = await _imapClient!.selectMailboxByPath(mailboxPath);
      await _imapClient!.deleteMailbox(mailbox);
      print('🗑️ Dossier supprimé: $mailboxPath');
    } catch (e) {
      print('❌ Erreur suppression dossier $mailboxPath: $e');
      rethrow;
    }
  }

  // Récupérer le corps complet d'un email spécifique (chargement à la demande)
  Future<Map<String, String>> fetchEmailBody(int uid, String mailboxPath) async {
    await connectImap();

    try {
      print('📥 Chargement du corps de l\'email UID $uid depuis $mailboxPath...');

      // Sélectionner le bon dossier
      await _imapClient!.selectMailboxByPath(mailboxPath);

      // Récupérer le message complet avec le corps
      final fetchResult = await _imapClient!.uidFetchMessages(
        MessageSequence.fromId(uid),
        '(BODY.PEEK[])',
      ).timeout(const Duration(seconds: 30));

      if (fetchResult.messages.isEmpty) {
        throw Exception('Email UID $uid introuvable dans $mailboxPath');
      }

      final message = fetchResult.messages.first;

      // Extraire le corps texte et HTML
      String body = '';
      String bodyHtml = '';

      if (message.decodeTextPlainPart() != null) {
        body = message.decodeTextPlainPart() ?? '';
      }

      if (message.decodeTextHtmlPart() != null) {
        bodyHtml = message.decodeTextHtmlPart() ?? '';
      }

      // Si pas de texte brut mais HTML, utiliser HTML comme body
      if (body.isEmpty && bodyHtml.isNotEmpty) {
        body = _stripHtmlTags(bodyHtml);
      }

      // Si toujours vide, message de secours
      if (body.isEmpty && bodyHtml.isEmpty) {
        body = '[Email sans contenu ou format non supporté]';
      }

      print('✅ Corps de l\'email chargé (${body.length} caractères)');

      return {
        'body': body,
        'bodyHtml': bodyHtml,
      };
    } catch (e) {
      print('❌ Erreur chargement corps email UID $uid: $e');
      rethrow;
    }
  }

  // Helper: Retirer les balises HTML
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}
