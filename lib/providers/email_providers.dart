import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/email_model.dart';
import '../models/mailbox_model.dart';
import '../services/gatekeeper_service.dart';
import '../services/email_service.dart';
import '../services/ai_service.dart';
import '../services/perplexity_service.dart';
import '../services/email_classifier_service.dart';
import '../services/secure_storage_service.dart';

// Provider pour SecureStorageService
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Provider pour EmailService
final emailServiceProvider = Provider<EmailService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return EmailService(secureStorage);
});

// Provider pour AiService
final aiServiceProvider = Provider<AiService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AiService(secureStorage);
});

// Provider pour PerplexityService
final perplexityServiceProvider = Provider<PerplexityService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return PerplexityService(secureStorage);
});

// Provider pour EmailClassifierService
final emailClassifierServiceProvider = Provider<EmailClassifierService>((ref) {
  return EmailClassifierService();
});

// Provider pour la liste des emails depuis Isar
final emailsProvider = StreamProvider<List<EmailModel>>((ref) {
  final isar = ref.watch(isarProvider);

  // Stream des emails triés par date (plus récent en premier)
  return isar.emailModels
      .where()
      .sortByDateDesc()
      .watch(fireImmediately: true);
});

// Provider pour synchroniser les emails (INBOX uniquement)
// Version RAPIDE avec classification par règles (sans IA)
final syncEmailsProvider = FutureProvider.autoDispose<void>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  final gatekeeperService = ref.watch(gatekeeperServiceProvider);
  final classifier = ref.watch(emailClassifierServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    print('🔄 SYNCHRONISATION RAPIDE INBOX (200 derniers)');
    print('⚡ Mode RAPIDE - Avec classification automatique');

    // Récupérer les 200 DERNIERS emails de INBOX
    final newEmails = await emailService.fetchEmailsFromMailbox(
      'INBOX',
      limit: 200, // 200 emails pour avoir l'historique complet
    );

    if (newEmails.isEmpty) {
      print('📭 Aucun email dans INBOX');
      return;
    }

    print('📊 ${newEmails.length} emails récupérés, filtrage des doublons...');

    // Récupérer tous les UIDs existants dans INBOX
    final localEmails = await isar.emailModels
        .filter()
        .mailboxPathEqualTo('INBOX')
        .findAll();

    final existingUidsSet = Set<int>.from(localEmails.map((e) => e.uid));
    final serverUidsSet = Set<int>.from(newEmails.map((e) => e.uid));

    // ✅ SYNCHRO SUPPRESSIONS: Emails supprimés du serveur
    final deletedUids = existingUidsSet.difference(serverUidsSet);
    if (deletedUids.isNotEmpty) {
      print('🗑️ ${deletedUids.length} emails supprimés depuis le webmail, nettoyage...');
      await isar.writeTxn(() async {
        for (final uid in deletedUids) {
          final emailToDelete = localEmails.firstWhere((e) => e.uid == uid);
          await isar.emailModels.delete(emailToDelete.id);
        }
      });
      print('✅ ${deletedUids.length} emails supprimés de la base locale');
    }

    // Filtrer les nouveaux emails
    final emailsToSave = <EmailModel>[];

    for (final email in newEmails) {
      if (existingUidsSet.contains(email.uid)) {
        continue;
      }

      // Gatekeeper check rapide
      final senderStatus = await gatekeeperService.getSenderStatus(email.displayEmail);
      if (senderStatus != null) {
        email.senderTrustStatus = senderStatus.isTrusted ? 'trusted' : 'blocked';
      } else {
        email.senderTrustStatus = 'unknown';
      }

      // 🔥 NOUVELLE: Classification automatique par règles
      final category = classifier.classifyEmail(
        from: email.displayEmail,
        subject: email.subject,
        body: email.body,
      );
      email.aiCategory = category;

      final importance = classifier.determineImportance(
        from: email.displayEmail,
        subject: email.subject,
        body: email.body,
        category: category,
      );
      email.aiImportance = importance;

      // Générer un résumé basique
      email.aiResume = classifier.generateBasicSummary(
        subject: email.subject,
        body: email.body,
      );

      // Marquer comme "analysé" par les règles (pas par l'IA Claude)
      email.isAiAnalyzed = true; // ✅ Maintenant analysé !

      emailsToSave.add(email);
    }

    if (emailsToSave.isEmpty) {
      print('✅ Tous les emails sont déjà synchronisés dans INBOX');
      return;
    }

    // Sauvegarder par batch de 100
    print('💾 Sauvegarde de ${emailsToSave.length} nouveaux emails...');

    final batchSize = 100;
    int totalSaved = 0;

    for (int i = 0; i < emailsToSave.length; i += batchSize) {
      final end = (i + batchSize < emailsToSave.length)
          ? i + batchSize
          : emailsToSave.length;

      final batch = emailsToSave.sublist(i, end);

      await isar.writeTxn(() async {
        final ids = await isar.emailModels.putAll(batch);
        totalSaved += ids.length;
        print('   ✓ Batch ${i ~/ batchSize + 1}: ${ids.length} emails sauvegardés (IDs: ${ids.first}...${ids.last})');
      });
    }

    // Vérifier le nombre total d'emails dans INBOX après sauvegarde
    final totalInInbox = await isar.emailModels
        .filter()
        .mailboxPathEqualTo('INBOX')
        .count();

    print('✅ ✨ Synchronisation INBOX terminée: ${emailsToSave.length} nouveaux emails sauvegardés');
    print('📊 Total dans INBOX après synchro: $totalInInbox emails');
    print('🏷️ Classification automatique appliquée (personnel/notification/newsletter)');
  } catch (e) {
    print('❌ Erreur synchronisation: $e');
    rethrow;
  }
});

// Provider pour supprimer un email
final deleteEmailProvider = FutureProvider.family<void, int>((ref, emailId) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    // Récupérer l'email depuis Isar
    final email = await isar.emailModels.get(emailId);

    if (email == null) {
      throw Exception('Email introuvable');
    }

    // Supprimer du serveur (avec le dossier correct)
    await emailService.deleteEmail(email.uid, email.mailboxPath);

    // Supprimer de la base locale
    await isar.writeTxn(() async {
      await isar.emailModels.delete(emailId);
    });

    print('🗑️ Email supprimé: ${email.subject}');
  } catch (e) {
    print('❌ Erreur suppression email: $e');
    rethrow;
  }
});

// Provider pour marquer un email comme lu
final markAsReadProvider = FutureProvider.family<void, int>((ref, emailId) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    final email = await isar.emailModels.get(emailId);

    if (email == null) {
      throw Exception('Email introuvable');
    }

    if (email.isRead) {
      return; // Déjà lu
    }

    // Marquer comme lu sur le serveur (avec le dossier correct)
    await emailService.markAsRead(email.uid, email.mailboxPath);

    // Mettre à jour localement
    email.isRead = true;
    email.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.emailModels.put(email);
    });

    print('✅ Email marqué comme lu: ${email.subject}');
  } catch (e) {
    print('⚠️ Erreur marquage lu: $e');
    rethrow;
  }
});

// Provider pour marquer un email comme NON lu
final markAsUnreadProvider = FutureProvider.family<void, int>((ref, emailId) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    final email = await isar.emailModels.get(emailId);

    if (email == null) {
      throw Exception('Email introuvable');
    }

    if (!email.isRead) {
      return; // Déjà non lu
    }

    // Marquer comme non lu sur le serveur
    await emailService.markAsUnread(email.uid, email.mailboxPath);

    // Mettre à jour localement
    email.isRead = false;
    email.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.emailModels.put(email);
    });

    print('✅ Email marqué comme non lu: ${email.subject}');
  } catch (e) {
    print('⚠️ Erreur marquage non lu: $e');
    rethrow;
  }
});

// Provider pour charger le corps complet d'un email (chargement à la demande)
final loadEmailBodyProvider = FutureProvider.family<EmailModel, int>((ref, emailId) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    // Récupérer l'email depuis Isar
    final email = await isar.emailModels.get(emailId);

    if (email == null) {
      throw Exception('Email introuvable');
    }

    // Vérifier si le corps est déjà chargé
    if (email.body.isNotEmpty &&
        !email.body.contains('[Corps non téléchargé') &&
        !email.body.contains('[Email sans contenu')) {
      print('✅ Corps de l\'email déjà chargé depuis la base locale');
      return email;
    }

    print('📥 Téléchargement du corps de l\'email UID ${email.uid}...');

    // Télécharger le corps depuis le serveur
    final bodyData = await emailService.fetchEmailBody(email.uid, email.mailboxPath);

    // Mettre à jour l'email avec le corps complet
    email.body = bodyData['body']!;
    email.bodyHtml = bodyData['bodyHtml']!;
    email.updatedAt = DateTime.now();

    // Sauvegarder dans Isar
    await isar.writeTxn(() async {
      await isar.emailModels.put(email);
    });

    print('✅ Corps de l\'email chargé et sauvegardé');
    return email;
  } catch (e) {
    print('❌ Erreur chargement corps email: $e');
    rethrow;
  }
});

// Provider pour déplacer un email vers un dossier
final moveEmailProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  final int emailId = params['emailId'];
  final String targetFolder = params['targetFolder'];

  try {
    final email = await isar.emailModels.get(emailId);

    if (email == null) {
      throw Exception('Email introuvable');
    }

    final sourceFolder = email.mailboxPath;

    if (sourceFolder == targetFolder) {
      print('⚠️ Email déjà dans le dossier $targetFolder');
      return;
    }

    // Déplacer sur le serveur
    await emailService.moveEmail(email.uid, sourceFolder, targetFolder);

    // Mettre à jour localement
    email.mailboxPath = targetFolder;
    email.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.emailModels.put(email);
    });

    print('📦 Email déplacé de $sourceFolder vers $targetFolder');
  } catch (e) {
    print('❌ Erreur déplacement email: $e');
    rethrow;
  }
});

// Provider pour envoyer un email
final sendEmailProvider = FutureProvider.family<void, Map<String, String>>((ref, data) async {
  final emailService = ref.watch(emailServiceProvider);

  try {
    await emailService.sendEmail(
      to: data['to']!,
      subject: data['subject']!,
      body: data['body']!,
      inReplyTo: data['inReplyTo'],
    );

    print('📤 Email envoyé à ${data['to']}');
  } catch (e) {
    print('❌ Erreur envoi email: $e');
    rethrow;
  }
});

// Provider pour le nombre d'emails non lus
final unreadCountProvider = StreamProvider<int>((ref) {
  final isar = ref.watch(isarProvider);

  return isar.emailModels
      .filter()
      .isReadEqualTo(false)
      .watch(fireImmediately: true)
      .map((emails) => emails.length);
});

// Provider pour filtrer les emails par importance
final emailsByImportanceProvider = StreamProvider.family<List<EmailModel>, String>((ref, importance) {
  final isar = ref.watch(isarProvider);

  return isar.emailModels
      .filter()
      .aiImportanceEqualTo(importance)
      .sortByDateDesc()
      .watch(fireImmediately: true);
});

// Provider pour filtrer les emails par catégorie
final emailsByCategoryProvider = StreamProvider.family<List<EmailModel>, String>((ref, category) {
  final isar = ref.watch(isarProvider);

  return isar.emailModels
      .filter()
      .aiCategoryEqualTo(category)
      .sortByDateDesc()
      .watch(fireImmediately: true);
});

// ============================================================================
// PROVIDERS MAILBOXES (gestion des dossiers IMAP)
// ============================================================================

// Provider pour le dossier actuellement sélectionné
final currentMailboxProvider = StateProvider<String>((ref) => 'INBOX');

// Provider pour la liste des mailboxes
final mailboxesProvider = FutureProvider<List<MailboxModel>>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    // Récupérer depuis le serveur
    final imapMailboxes = await emailService.getMailboxes();

    // Convertir en MailboxModel
    final mailboxModels = imapMailboxes
        .map((m) => MailboxModel.fromImapMailbox(m))
        .toList();

    // Sauvegarder dans Isar
    await isar.writeTxn(() async {
      await isar.mailboxModels.clear();
      await isar.mailboxModels.putAll(mailboxModels);
    });

    print('📂 ${mailboxModels.length} dossiers synchronisés dans Isar');
    return mailboxModels;
  } catch (e) {
    print('❌ Erreur récupération mailboxes: $e');
    rethrow;
  }
});

// Provider pour les emails du dossier actuel
final currentMailboxEmailsProvider = StreamProvider<List<EmailModel>>((ref) {
  final currentMailbox = ref.watch(currentMailboxProvider);
  final isar = ref.watch(isarProvider);

  // Stream des emails du dossier actuel
  return isar.emailModels
      .filter()
      .mailboxPathEqualTo(currentMailbox)
      .sortByDateDesc()
      .watch(fireImmediately: true);
});

// Provider pour créer un nouveau dossier
final createMailboxProvider = FutureProvider.family<void, String>((ref, mailboxName) async {
  final emailService = ref.watch(emailServiceProvider);

  try {
    await emailService.createMailbox(mailboxName);

    // Rafraîchir la liste des dossiers
    ref.invalidate(mailboxesProvider);

    print('📁 Dossier créé: $mailboxName');
  } catch (e) {
    print('❌ Erreur création dossier: $e');
    rethrow;
  }
});

// Provider pour renommer un dossier
final renameMailboxProvider = FutureProvider.family<void, Map<String, String>>((ref, params) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  final String oldPath = params['oldPath']!;
  final String newPath = params['newPath']!;

  try {
    await emailService.renameMailbox(oldPath, newPath);

    // Mettre à jour le mailboxPath de tous les emails du dossier renommé
    final emailsToUpdate = await isar.emailModels
        .filter()
        .mailboxPathEqualTo(oldPath)
        .findAll();

    if (emailsToUpdate.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final email in emailsToUpdate) {
          email.mailboxPath = newPath;
          await isar.emailModels.put(email);
        }
      });
      print('📝 ${emailsToUpdate.length} emails mis à jour avec le nouveau chemin');
    }

    // Rafraîchir la liste des dossiers
    ref.invalidate(mailboxesProvider);

    print('✏️ Dossier renommé: $oldPath → $newPath');
  } catch (e) {
    print('❌ Erreur renommage dossier: $e');
    rethrow;
  }
});

// Provider pour supprimer un dossier
final deleteMailboxProvider = FutureProvider.family<void, String>((ref, mailboxPath) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    // Supprimer d'abord tous les emails du dossier localement
    final emailsToDelete = await isar.emailModels
        .filter()
        .mailboxPathEqualTo(mailboxPath)
        .findAll();

    if (emailsToDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final email in emailsToDelete) {
          await isar.emailModels.delete(email.id);
        }
      });
      print('🗑️ ${emailsToDelete.length} emails supprimés du dossier');
    }

    // Supprimer le dossier sur le serveur
    await emailService.deleteMailbox(mailboxPath);

    // Rafraîchir la liste des dossiers
    ref.invalidate(mailboxesProvider);

    print('🗑️ Dossier supprimé: $mailboxPath');
  } catch (e) {
    print('❌ Erreur suppression dossier: $e');
    rethrow;
  }
});

// Provider pour FORCER une resynchronisation complète (vider + re-télécharger TOUT)
final forceFullResyncProvider = FutureProvider.family<void, String>((ref, mailboxPath) async {
  final emailService = ref.watch(emailServiceProvider);
  final gatekeeperService = ref.watch(gatekeeperServiceProvider);
  final classifier = ref.watch(emailClassifierServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    print('🔄 🔥 RESYNCHRONISATION COMPLÈTE FORCÉE: $mailboxPath');
    print('⚠️ Suppression de tous les emails locaux de $mailboxPath...');

    // ÉTAPE 1: VIDER complètement le dossier local
    final localEmails = await isar.emailModels
        .filter()
        .mailboxPathEqualTo(mailboxPath)
        .findAll();

    if (localEmails.isNotEmpty) {
      await isar.writeTxn(() async {
        for (final email in localEmails) {
          await isar.emailModels.delete(email.id);
        }
      });
      print('🗑️ ${localEmails.length} emails locaux supprimés');
    }

    // ÉTAPE 2: Re-télécharger TOUS les emails du serveur (limite 500 pour avoir tout l'historique)
    print('📥 Téléchargement de TOUS les emails depuis le serveur...');
    final newEmails = await emailService.fetchEmailsFromMailbox(
      mailboxPath,
      limit: 500, // 500 emails pour couvrir plusieurs mois d'historique
    );

    if (newEmails.isEmpty) {
      print('📭 Aucun email dans $mailboxPath sur le serveur');
      return;
    }

    print('📊 ${newEmails.length} emails récupérés depuis le serveur');

    // ÉTAPE 3: Classifier et sauvegarder TOUS
    final emailsToSave = <EmailModel>[];

    for (final email in newEmails) {
      // Gatekeeper check
      final senderStatus = await gatekeeperService.getSenderStatus(email.displayEmail);
      if (senderStatus != null) {
        email.senderTrustStatus = senderStatus.isTrusted ? 'trusted' : 'blocked';
      } else {
        email.senderTrustStatus = 'unknown';
      }

      // Classification
      final category = classifier.classifyEmail(
        from: email.displayEmail,
        subject: email.subject,
        body: email.body,
      );
      email.aiCategory = category;

      final importance = classifier.determineImportance(
        from: email.displayEmail,
        subject: email.subject,
        body: email.body,
        category: category,
      );
      email.aiImportance = importance;

      email.aiResume = classifier.generateBasicSummary(
        subject: email.subject,
        body: email.body,
      );

      email.isAiAnalyzed = true;
      emailsToSave.add(email);
    }

    // ÉTAPE 4: Sauvegarder par batch
    print('💾 Sauvegarde de ${emailsToSave.length} emails...');

    final batchSize = 100;
    for (int i = 0; i < emailsToSave.length; i += batchSize) {
      final end = (i + batchSize < emailsToSave.length) ? i + batchSize : emailsToSave.length;
      final batch = emailsToSave.sublist(i, end);

      await isar.writeTxn(() async {
        final ids = await isar.emailModels.putAll(batch);
        print('   ✓ Batch ${i ~/ batchSize + 1}: ${ids.length} emails sauvegardés');
      });
    }

    final total = await isar.emailModels.filter().mailboxPathEqualTo(mailboxPath).count();
    print('✅ ✨ RESYNCHRONISATION COMPLÈTE TERMINÉE');
    print('📊 Total dans $mailboxPath: $total emails');
  } catch (e) {
    print('❌ Erreur resynchronisation complète: $e');
    rethrow;
  }
});

// Provider pour synchroniser les emails d'un dossier spécifique avec limite dynamique
// Version RAPIDE avec classification par règles (sans IA)
final syncMailboxEmailsWithLimitProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final String mailboxPath = params['mailboxPath'] as String;
  final int limit = params['limit'] as int? ?? 200;

  final emailService = ref.watch(emailServiceProvider);
  final gatekeeperService = ref.watch(gatekeeperServiceProvider);
  final classifier = ref.watch(emailClassifierServiceProvider);
  final isar = ref.watch(isarProvider);

  try {
    print('🔄 SYNCHRONISATION RAPIDE: $mailboxPath ($limit derniers)');
    print('⚡ Mode RAPIDE - Avec classification automatique');

    // Récupérer les emails du dossier avec la limite spécifiée
    final newEmails = await emailService.fetchEmailsFromMailbox(
      mailboxPath,
      limit: limit,
    );

    if (newEmails.isEmpty) {
      print('📭 Aucun email dans $mailboxPath');
      return;
    }

    print('📊 ${newEmails.length} emails récupérés, filtrage des doublons...');

    // Récupérer tous les emails existants dans ce dossier
    final localEmails = await isar.emailModels
        .filter()
        .mailboxPathEqualTo(mailboxPath)
        .findAll();

    final existingUidsSet = Set<int>.from(localEmails.map((e) => e.uid));
    final serverUidsSet = Set<int>.from(newEmails.map((e) => e.uid));

    // ✅ SYNCHRO SUPPRESSIONS: Emails supprimés du serveur
    final deletedUids = existingUidsSet.difference(serverUidsSet);
    if (deletedUids.isNotEmpty) {
      print('🗑️ ${deletedUids.length} emails supprimés depuis le webmail, nettoyage...');
      await isar.writeTxn(() async {
        for (final uid in deletedUids) {
          final emailToDelete = localEmails.firstWhere((e) => e.uid == uid);
          await isar.emailModels.delete(emailToDelete.id);
        }
      });
      print('✅ ${deletedUids.length} emails supprimés de la base locale');
    }

    // Filtrer les nouveaux emails
    final emailsToSave = <EmailModel>[];

    for (final email in newEmails) {
      if (existingUidsSet.contains(email.uid)) {
        continue; // Déjà existant
      }

      // Gatekeeper check rapide
      final senderStatus = await gatekeeperService.getSenderStatus(email.displayEmail);
      if (senderStatus != null) {
        email.senderTrustStatus = senderStatus.isTrusted ? 'trusted' : 'blocked';
      } else {
        email.senderTrustStatus = 'unknown';
      }

      // 🔥 NOUVELLE: Classification automatique par règles
      final category = classifier.classifyEmail(
        from: email.displayEmail,
        subject: email.subject,
        body: email.body,
      );
      email.aiCategory = category;

      final importance = classifier.determineImportance(
        from: email.displayEmail,
        subject: email.subject,
        body: email.body,
        category: category,
      );
      email.aiImportance = importance;

      // Générer un résumé basique
      email.aiResume = classifier.generateBasicSummary(
        subject: email.subject,
        body: email.body,
      );

      // Marquer comme "analysé" par les règles
      email.isAiAnalyzed = true; // ✅ Maintenant analysé !

      emailsToSave.add(email);
    }

    if (emailsToSave.isEmpty) {
      print('✅ Tous les emails sont déjà synchronisés dans $mailboxPath');
      return;
    }

    // Sauvegarder par batch de 100 pour optimiser
    print('💾 Sauvegarde de ${emailsToSave.length} nouveaux emails...');

    final batchSize = 100;
    int totalSaved = 0;

    for (int i = 0; i < emailsToSave.length; i += batchSize) {
      final end = (i + batchSize < emailsToSave.length)
          ? i + batchSize
          : emailsToSave.length;

      final batch = emailsToSave.sublist(i, end);

      await isar.writeTxn(() async {
        final ids = await isar.emailModels.putAll(batch);
        totalSaved += ids.length;
        print('   ✓ Batch ${i ~/ batchSize + 1}: ${ids.length} emails sauvegardés (IDs: ${ids.first}...${ids.last})');
      });
    }

    // Vérifier le nombre total d'emails dans le dossier après sauvegarde
    final totalInMailbox = await isar.emailModels
        .filter()
        .mailboxPathEqualTo(mailboxPath)
        .count();

    print('✅ ✨ Synchronisation $mailboxPath terminée: ${emailsToSave.length} nouveaux emails sauvegardés');
    print('📊 Total dans $mailboxPath après synchro: $totalInMailbox emails');
    print('🏷️ Classification automatique appliquée (personnel/notification/newsletter)');
  } catch (e) {
    print('❌ Erreur synchronisation $mailboxPath: $e');
    rethrow;
  }
});

// Provider pour synchroniser les emails d'un dossier spécifique (compatibilité)
// Version RAPIDE avec classification par règles (sans IA)
final syncMailboxEmailsProvider = FutureProvider.family<void, String>((ref, mailboxPath) async {
  return ref.read(syncMailboxEmailsWithLimitProvider({'mailboxPath': mailboxPath, 'limit': 200}).future);
});
