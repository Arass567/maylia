import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../models/email_model.dart';
import 'email_service.dart';
import 'perplexity_service.dart';
import 'secure_storage_service.dart';

class JarvisService {
  final SecureStorageService _secureStorage;

  // API Key chargée de manière asynchrone depuis le stockage sécurisé
  String? _apiKey;
  bool _apiKeyLoaded = false;

  final String _apiUrl = 'https://api.anthropic.com/v1/messages';
  final String _model = 'claude-sonnet-4-5-20250929'; // Claude Sonnet 4.5 - Le modèle le plus puissant d'Anthropic

  final EmailService _emailService;
  final PerplexityService _perplexityService;
  final Isar _isar;

  // Historique de conversation
  final List<Map<String, dynamic>> _conversationHistory = [];

  JarvisService({
    required SecureStorageService secureStorage,
    required EmailService emailService,
    required PerplexityService perplexityService,
    required Isar isar,
  })  : _secureStorage = secureStorage,
        _emailService = emailService,
        _perplexityService = perplexityService,
        _isar = isar {
    // Message système initial
    _conversationHistory.add({
      'role': 'user',
      'content': _getSystemPrompt(),
    });
  }

  /// Charge l'API Key depuis le stockage sécurisé (lazy loading).
  Future<void> _loadApiKey() async {
    if (_apiKeyLoaded) return; // Déjà chargée, skip

    print('🔐 Chargement de l\'API Key Anthropic depuis le stockage sécurisé (Jarvis)...');
    try {
      _apiKey = await _secureStorage.getAnthropicApiKey();
      _apiKeyLoaded = true;
      print('✅ API Key Anthropic chargée depuis le stockage sécurisé (Jarvis)');
    } catch (e) {
      print('❌ Erreur chargement API Key Anthropic (Jarvis): $e');
      rethrow;
    }
  }

  // Prompt système pour l'Assistant IA
  String _getSystemPrompt() {
    return '''Tu es un assistant IA personnel pour gérer la messagerie La Poste.

Tu peux :
- Lire et résumer les emails de n'importe quel dossier
- Changer de dossier (INBOX, Sent, Trash, Spam, Archive, etc.)
- Rechercher des emails
- Envoyer et répondre à des emails
- Déplacer des emails entre dossiers
- Supprimer des emails

Ton style :
- Professionnel et efficace
- Concis et clair
- Utilise des expressions comme "Bien sûr", "Voilà", "C'est fait"

Utilise les outils à ta disposition pour répondre aux demandes.''';
  }

  // Définition des tools disponibles pour Jarvis
  List<Map<String, dynamic>> _getTools() {
    return [
      {
        'name': 'read_emails',
        'description':
            'Lit les emails de la boîte de réception. Peut filtrer par importance ou récupérer uniquement les non lus.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'filter': {
              'type': 'string',
              'enum': ['all', 'unread', 'haute', 'moyenne', 'faible'],
              'description': 'Filtre à appliquer : all (tous), unread (non lus), ou par importance',
            },
            'limit': {
              'type': 'number',
              'description': 'Nombre maximum d\'emails à retourner (défaut: 10)',
            },
          },
          'required': ['filter'],
        },
      },
      {
        'name': 'search_emails',
        'description': 'Recherche des emails par expéditeur, sujet ou contenu.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'Texte à rechercher dans les emails',
            },
            'field': {
              'type': 'string',
              'enum': ['all', 'from', 'subject', 'body'],
              'description': 'Champ où rechercher : all, from, subject, ou body',
            },
          },
          'required': ['query', 'field'],
        },
      },
      {
        'name': 'get_email_details',
        'description': 'Obtient les détails complets d\'un email spécifique.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'email_id': {
              'type': 'number',
              'description': 'L\'ID de l\'email à récupérer',
            },
          },
          'required': ['email_id'],
        },
      },
      {
        'name': 'send_email',
        'description': 'Envoie un nouvel email.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'to': {
              'type': 'string',
              'description': 'Adresse email du destinataire',
            },
            'subject': {
              'type': 'string',
              'description': 'Sujet de l\'email',
            },
            'body': {
              'type': 'string',
              'description': 'Corps du message',
            },
          },
          'required': ['to', 'subject', 'body'],
        },
      },
      {
        'name': 'reply_to_email',
        'description': 'Répond à un email existant.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'email_id': {
              'type': 'number',
              'description': 'L\'ID de l\'email auquel répondre',
            },
            'message': {
              'type': 'string',
              'description': 'Le message de réponse',
            },
          },
          'required': ['email_id', 'message'],
        },
      },
      {
        'name': 'delete_email',
        'description': 'Supprime un email définitivement.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'email_id': {
              'type': 'number',
              'description': 'L\'ID de l\'email à supprimer',
            },
          },
          'required': ['email_id'],
        },
      },
      {
        'name': 'get_unread_count',
        'description': 'Obtient le nombre d\'emails non lus.',
        'input_schema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'sync_emails',
        'description': 'Synchronise les emails avec le serveur pour récupérer les nouveaux.',
        'input_schema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'search_web',
        'description': 'Effectue une recherche sur le web pour trouver des informations récentes, vérifier des faits ou obtenir des détails sur un sujet.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'La requête de recherche',
            },
          },
          'required': ['query'],
        },
      },
      {
        'name': 'list_mailboxes',
        'description':
            'Liste tous les dossiers disponibles (Inbox, Sent, Trash, Spam, etc.).',
        'input_schema': {
          'type': 'object',
          'properties': {},
        },
      },
      {
        'name': 'select_mailbox',
        'description': 'Change le dossier actif pour consulter ses emails.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'mailbox_path': {
              'type': 'string',
              'description':
                  'Le chemin du dossier (ex: "INBOX", "Sent", "Spam")',
            },
          },
          'required': ['mailbox_path'],
        },
      },
      {
        'name': 'move_email',
        'description': 'Déplace un email vers un autre dossier.',
        'input_schema': {
          'type': 'object',
          'properties': {
            'email_id': {
              'type': 'number',
              'description': 'L\'ID de l\'email à déplacer',
            },
            'target_folder': {
              'type': 'string',
              'description':
                  'Le dossier de destination (ex: "Trash", "Archive")',
            },
          },
          'required': ['email_id', 'target_folder'],
        },
      },
    ];
  }

  // Fonction principale : envoyer un message à Jarvis
  Future<String> sendMessage(String userMessage) async {
    // 0. Charger l'API Key si pas encore fait
    await _loadApiKey();

    if (_apiKey == null || _apiKey!.isEmpty) {
      return '❌ Erreur : ANTHROPIC_API_KEY non configurée.';
    }

    try {
      // Ajouter le message de l'utilisateur
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // Appel à l'API Claude avec tools
      var response = await _callClaudeAPI();

      // Boucle pour gérer les appels de fonctions multiples
      while (response['stop_reason'] == 'tool_use') {
        // IMPORTANT: Ajouter d'abord la réponse de l'assistant à l'historique
        _conversationHistory.add({
          'role': 'assistant',
          'content': response['content'],
        });

        // Extraire les tool uses
        final toolUses = response['content']
            .where((block) => block['type'] == 'tool_use')
            .toList();

        // Exécuter chaque tool
        final toolResults = <Map<String, dynamic>>[];
        for (final toolUse in toolUses) {
          final result = await _executeToolInternal(
            toolUse['name'],
            toolUse['input'],
          );

          toolResults.add({
            'type': 'tool_result',
            'tool_use_id': toolUse['id'],
            'content': result,
          });
        }

        // Ajouter les résultats à l'historique
        _conversationHistory.add({
          'role': 'user',
          'content': toolResults,
        });

        // Rappeler Claude avec les résultats
        response = await _callClaudeAPI();
      }

      // Extraire la réponse textuelle
      final textBlocks = response['content']
          .where((block) => block['type'] == 'text')
          .toList();

      if (textBlocks.isEmpty) {
        return '🤖 JARVIS : Désolé, je n\'ai pas pu traiter votre demande.';
      }

      final assistantMessage = textBlocks.first['text'];

      // Ajouter à l'historique
      _conversationHistory.add({
        'role': 'assistant',
        'content': response['content'],
      });

      return assistantMessage;
    } catch (e) {
      print('❌ Erreur Jarvis: $e');
      return '🤖 JARVIS : Désolé, une erreur s\'est produite : $e';
    }
  }

  // Appeler l'API Claude
  Future<Map<String, dynamic>> _callClaudeAPI() async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 2000,
        'tools': _getTools(),
        'messages': _conversationHistory.skip(1).toList(), // Skip system prompt
        'system': _getSystemPrompt(),
      }),
    );

    if (response.statusCode != 200) {
      print('❌ Erreur API: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Erreur API: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }

  // Exécuter un tool (fonction interne)
  Future<String> _executeToolInternal(
    String toolName,
    Map<String, dynamic> input,
  ) async {
    print('🔧 Exécution de $toolName avec input: $input');

    try {
      switch (toolName) {
        case 'read_emails':
          return await _readEmails(input);

        case 'search_emails':
          return await _searchEmails(input);

        case 'get_email_details':
          return await _getEmailDetails(input);

        case 'send_email':
          return await _sendEmail(input);

        case 'reply_to_email':
          return await _replyToEmail(input);

        case 'delete_email':
          return await _deleteEmail(input);

        case 'get_unread_count':
          return await _getUnreadCount();

        case 'sync_emails':
          return await _syncEmails();

        case 'search_web':
        return await _perplexityService.searchWeb(input['query']);
      case 'list_mailboxes':
          return await _listMailboxes();

        case 'select_mailbox':
          return await _selectMailbox(input);

        case 'move_email':
          return await _moveEmail(input);

        default:
          return 'Fonction inconnue : $toolName';
      }
    } catch (e) {
      return 'Erreur lors de l\'exécution de $toolName : $e';
    }
  }

  // === IMPLÉMENTATION DES TOOLS ===

  Future<String> _readEmails(Map<String, dynamic> input) async {
    final filter = input['filter'] ?? 'all';
    final limit = (input['limit'] ?? 10).toInt();

    List<EmailModel> emails;

    switch (filter) {
      case 'unread':
        emails = await _isar.emailModels
            .filter()
            .isReadEqualTo(false)
            .sortByDateDesc()
            .limit(limit)
            .findAll();
        break;

      case 'haute':
      case 'moyenne':
      case 'faible':
        emails = await _isar.emailModels
            .filter()
            .aiImportanceEqualTo(filter)
            .sortByDateDesc()
            .limit(limit)
            .findAll();
        break;

      default:
        emails = await _isar.emailModels
            .where()
            .sortByDateDesc()
            .limit(limit)
            .findAll();
    }

    if (emails.isEmpty) {
      return 'Aucun email trouvé avec le filtre "$filter".';
    }

    // Formater les emails pour Claude
    final emailList = emails.map((e) {
      return {
        'id': e.id,
        'from': e.displayFrom,
        'email': e.displayEmail,
        'subject': e.subject,
        'date': e.date.toIso8601String(),
        'is_read': e.isRead,
        'importance': e.aiImportance,
        'category': e.aiCategory,
        'resume': e.aiResume,
      };
    }).toList();

    return jsonEncode({
      'count': emails.length,
      'emails': emailList,
    });
  }

  Future<String> _searchEmails(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final field = input['field'] ?? 'all';

    List<EmailModel> emails = await _isar.emailModels
        .where()
        .sortByDateDesc()
        .findAll();

    // Filtrer selon le champ
    emails = emails.where((email) {
      final searchQuery = query.toLowerCase();

      switch (field) {
        case 'from':
          return email.from.toLowerCase().contains(searchQuery);
        case 'subject':
          return email.subject.toLowerCase().contains(searchQuery);
        case 'body':
          return email.body.toLowerCase().contains(searchQuery);
        default:
          return email.from.toLowerCase().contains(searchQuery) ||
              email.subject.toLowerCase().contains(searchQuery) ||
              email.body.toLowerCase().contains(searchQuery);
      }
    }).toList();

    if (emails.isEmpty) {
      return 'Aucun email trouvé pour la recherche "$query" dans $field.';
    }

    final emailList = emails.take(10).map((e) {
      return {
        'id': e.id,
        'from': e.displayFrom,
        'subject': e.subject,
        'date': e.date.toIso8601String(),
        'resume': e.aiResume,
      };
    }).toList();

    return jsonEncode({
      'count': emails.length,
      'showing': emailList.length,
      'emails': emailList,
    });
  }

  Future<String> _getEmailDetails(Map<String, dynamic> input) async {
    final emailId = (input['email_id'] as num).toInt();

    final email = await _isar.emailModels.get(emailId);

    if (email == null) {
      return 'Email avec l\'ID $emailId introuvable.';
    }

    return jsonEncode({
      'id': email.id,
      'from': email.displayFrom,
      'email': email.displayEmail,
      'to': email.to,
      'subject': email.subject,
      'body': email.body,
      'date': email.date.toIso8601String(),
      'is_read': email.isRead,
      'importance': email.aiImportance,
      'category': email.aiCategory,
      'resume': email.aiResume,
      'has_attachments': email.hasAttachments,
    });
  }

  Future<String> _sendEmail(Map<String, dynamic> input) async {
    final to = input['to'] as String;
    final subject = input['subject'] as String;
    final body = input['body'] as String;

    await _emailService.sendEmail(
      to: to,
      subject: subject,
      body: body,
    );

    return 'Email envoyé avec succès à $to.';
  }

  Future<String> _replyToEmail(Map<String, dynamic> input) async {
    final emailId = (input['email_id'] as num).toInt();
    final message = input['message'] as String;

    final email = await _isar.emailModels.get(emailId);

    if (email == null) {
      return 'Email avec l\'ID $emailId introuvable.';
    }

    await _emailService.sendEmail(
      to: email.displayEmail,
      subject: 'Re: ${email.subject}',
      body: message,
    );

    return 'Réponse envoyée avec succès à ${email.displayFrom}.';
  }

  Future<String> _deleteEmail(Map<String, dynamic> input) async {
    final emailId = (input['email_id'] as num).toInt();

    final email = await _isar.emailModels.get(emailId);

    if (email == null) {
      return 'Email avec l\'ID $emailId introuvable.';
    }

    // Supprimer du serveur (avec le dossier correct)
    await _emailService.deleteEmail(email.uid, email.mailboxPath);

    // Supprimer localement
    await _isar.writeTxn(() async {
      await _isar.emailModels.delete(emailId);
    });

    return 'Email de ${email.displayFrom} supprimé définitivement.';
  }

  Future<String> _getUnreadCount() async {
    final count = await _isar.emailModels
        .filter()
        .isReadEqualTo(false)
        .count();

    return 'Vous avez $count email(s) non lu(s).';
  }

  Future<String> _syncEmails() async {
    final newEmails = await _emailService.fetchAllEmails(limit: 30);

    int added = 0;
    for (final email in newEmails) {
      final exists = await _isar.emailModels
          .filter()
          .uidEqualTo(email.uid)
          .findFirst();

      if (exists == null) {
        await _isar.writeTxn(() async {
          await _isar.emailModels.put(email);
        });
        added++;
      }
    }

    return 'Synchronisation terminée. $added nouveau(x) email(s) récupéré(s).';
  }

  // === NOUVEAUX TOOLS POUR LES DOSSIERS ===

  Future<String> _listMailboxes() async {
    final mailboxes = await _emailService.getMailboxes();

    final mailboxList = mailboxes.map((m) {
      return {
        'path': m.path,
        'name': m.name,
        'message_count': m.messagesExists,
        'unseen_count': m.messagesUnseen,
        'is_inbox': m.isInbox,
        'is_sent': m.isSent,
        'is_trash': m.isTrash,
        'is_spam': m.isJunk,
      };
    }).toList();

    return jsonEncode({
      'count': mailboxes.length,
      'mailboxes': mailboxList,
    });
  }

  Future<String> _selectMailbox(Map<String, dynamic> input) async {
    final mailboxPath = input['mailbox_path'] as String;

    try {
      await _emailService.selectMailbox(mailboxPath);

      // Synchroniser les emails du nouveau dossier
      final emails = await _emailService.fetchEmailsFromMailbox(
        mailboxPath,
        limit: 20,
      );

      int added = 0;
      for (final email in emails) {
        final exists = await _isar.emailModels
            .filter()
            .uidEqualTo(email.uid)
            .findFirst();

        if (exists == null) {
          await _isar.writeTxn(() async {
            await _isar.emailModels.put(email);
          });
          added++;
        }
      }

      return 'Dossier "$mailboxPath" sélectionné. $added email(s) chargé(s).';
    } catch (e) {
      return 'Erreur lors de la sélection du dossier "$mailboxPath": $e';
    }
  }

  Future<String> _moveEmail(Map<String, dynamic> input) async {
    final emailId = (input['email_id'] as num).toInt();
    final targetFolder = input['target_folder'] as String;

    final email = await _isar.emailModels.get(emailId);

    if (email == null) {
      return 'Email avec l\'ID $emailId introuvable.';
    }

    try {
      // Déplacer sur le serveur (avec dossier source et cible)
      await _emailService.moveEmail(email.uid, email.mailboxPath, targetFolder);

      // Mettre à jour le champ mailboxPath dans Isar
      email.mailboxPath = targetFolder;
      await _isar.writeTxn(() async {
        await _isar.emailModels.put(email);
      });

      return 'Email de ${email.displayFrom} déplacé vers "$targetFolder" avec succès.';
    } catch (e) {
      return 'Erreur lors du déplacement: $e';
    }
  }

  // Réinitialiser la conversation
  void resetConversation() {
    _conversationHistory.clear();
    _conversationHistory.add({
      'role': 'user',
      'content': _getSystemPrompt(),
    });
  }
}
