import 'package:isar/isar.dart';
import '../models/chat_session.dart';
import 'ai_service.dart';

/// Service pour gérer les sessions de conversation avec JARVIS
class ChatSessionService {
  final Isar isar;
  final AiService aiService;

  ChatSessionService({
    required this.isar,
    required this.aiService,
  });

  /// Créer une nouvelle session de chat
  Future<ChatSession> createSession({
    String? title,
    List<ChatMessage>? initialMessages,
  }) async {
    final session = ChatSession.create(
      title: title,
      initialMessages: initialMessages,
    );

    await isar.writeTxn(() async {
      await isar.chatSessions.put(session);
    });

    print('💬 Nouvelle session créée: ${session.title} (ID: ${session.id})');
    return session;
  }

  /// Récupérer toutes les sessions (triées par date de modification)
  Future<List<ChatSession>> getAllSessions() async {
    return await isar.chatSessions
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// Stream de toutes les sessions
  Stream<List<ChatSession>> watchAllSessions() {
    return isar.chatSessions
        .where()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Récupérer une session par ID
  Future<ChatSession?> getSession(int sessionId) async {
    return await isar.chatSessions.get(sessionId);
  }

  /// Mettre à jour une session
  Future<void> updateSession(ChatSession session) async {
    session.updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.chatSessions.put(session);
    });

    print('✏️ Session mise à jour: ${session.title}');
  }

  /// Ajouter un message à une session
  Future<void> addMessageToSession(
    int sessionId,
    ChatMessage message,
  ) async {
    final session = await getSession(sessionId);

    if (session == null) {
      throw Exception('Session $sessionId introuvable');
    }

    session.addMessage(message);
    await updateSession(session);
  }

  /// Remplacer tous les messages d'une session
  Future<void> setSessionMessages(
    int sessionId,
    List<ChatMessage> messages,
  ) async {
    final session = await getSession(sessionId);

    if (session == null) {
      throw Exception('Session $sessionId introuvable');
    }

    session.setMessages(messages);
    await updateSession(session);
  }

  /// Générer un titre intelligent pour une session basé sur les messages
  Future<String> generateSmartTitle(ChatSession session) async {
    final messages = session.getMessages();

    if (messages.isEmpty) {
      return 'Nouvelle conversation';
    }

    // Récupérer les 3 premiers messages utilisateur
    final userMessages = messages
        .where((m) => m.role == 'user')
        .take(3)
        .map((m) => m.content)
        .join('\n');

    if (userMessages.isEmpty) {
      return 'Conversation ${_formatDate(session.createdAt)}';
    }

    try {
      // Demander à Claude de générer un titre court
      final prompt = 'Génère un titre court et descriptif (maximum 50 caractères) pour cette conversation :\n\n$userMessages\n\nRéponds uniquement avec le titre, sans guillemets ni ponctuation finale.';

      final analysis = await aiService.analyzeEmail(
        subject: 'Titre de conversation',
        body: userMessages,
      );

      final title = analysis.resume.trim();

      // Vérifier la longueur
      if (title.length > 60) {
        return '${title.substring(0, 57)}...';
      }

      return title;
    } catch (e) {
      print('⚠️ Erreur génération titre: $e');
      // Fallback: utiliser le premier message
      return session.generateAutoTitle();
    }
  }

  /// Mettre à jour le titre d'une session avec génération IA
  Future<void> updateSessionTitle(int sessionId) async {
    final session = await getSession(sessionId);

    if (session == null) {
      throw Exception('Session $sessionId introuvable');
    }

    final newTitle = await generateSmartTitle(session);
    session.title = newTitle;
    await updateSession(session);

    print('📝 Titre généré: "$newTitle"');
  }

  /// Désactiver toutes les sessions actives (quand on commence une nouvelle)
  Future<void> deactivateAllSessions() async {
    final activeSessions = await isar.chatSessions
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    if (activeSessions.isEmpty) return;

    await isar.writeTxn(() async {
      for (final session in activeSessions) {
        session.isActive = false;
        await isar.chatSessions.put(session);
      }
    });

    print('🔒 ${activeSessions.length} session(s) désactivée(s)');
  }

  /// Activer une session spécifique
  Future<void> activateSession(int sessionId) async {
    // D'abord désactiver toutes les autres
    await deactivateAllSessions();

    final session = await getSession(sessionId);

    if (session == null) {
      throw Exception('Session $sessionId introuvable');
    }

    session.isActive = true;
    await updateSession(session);

    print('🔓 Session activée: ${session.title}');
  }

  /// Récupérer la session active actuelle
  Future<ChatSession?> getActiveSession() async {
    return await isar.chatSessions
        .filter()
        .isActiveEqualTo(true)
        .findFirst();
  }

  /// Supprimer une session
  Future<void> deleteSession(int sessionId) async {
    await isar.writeTxn(() async {
      final deleted = await isar.chatSessions.delete(sessionId);
      if (deleted) {
        print('🗑️ Session $sessionId supprimée');
      }
    });
  }

  /// Supprimer toutes les sessions
  Future<void> deleteAllSessions() async {
    final count = await isar.chatSessions.count();

    await isar.writeTxn(() async {
      await isar.chatSessions.clear();
    });

    print('🗑️ $count session(s) supprimée(s)');
  }

  /// Récupérer le nombre total de sessions
  Future<int> getSessionCount() async {
    return await isar.chatSessions.count();
  }

  /// Créer une nouvelle session et la rendre active
  Future<ChatSession> createAndActivateSession({
    String? title,
    List<ChatMessage>? initialMessages,
  }) async {
    // Désactiver les autres sessions
    await deactivateAllSessions();

    // Créer la nouvelle session
    final session = await createSession(
      title: title,
      initialMessages: initialMessages,
    );

    // L'activer
    session.isActive = true;
    await updateSession(session);

    return session;
  }

  /// Formater une date pour l'affichage
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Nettoyer les anciennes sessions (plus de 90 jours)
  Future<int> cleanOldSessions({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final oldSessions = await isar.chatSessions
        .filter()
        .updatedAtLessThan(cutoffDate)
        .findAll();

    if (oldSessions.isEmpty) return 0;

    final count = oldSessions.length;

    await isar.writeTxn(() async {
      for (final session in oldSessions) {
        await isar.chatSessions.delete(session.id);
      }
    });

    print('🧹 $count session(s) ancienne(s) supprimée(s)');
    return count;
  }
}
