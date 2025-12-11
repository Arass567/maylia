import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart' as session_model;
import '../services/jarvis_service.dart';
import '../services/chat_session_service.dart';
import 'email_providers.dart';
import 'chat_session_providers.dart';

// Provider pour JarvisService
final jarvisServiceProvider = Provider<JarvisService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final emailService = ref.watch(emailServiceProvider);
  final perplexityService = ref.watch(perplexityServiceProvider);
  final isar = ref.watch(isarProvider);

  return JarvisService(
    secureStorage: secureStorage,
    emailService: emailService,
    perplexityService: perplexityService,
    isar: isar,
  );
});

// Provider pour la liste des messages de chat
final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final isar = ref.watch(isarProvider);

  return isar.chatMessages
      .where()
      .sortByTimestamp()
      .watch(fireImmediately: true);
});

// Provider pour envoyer un message à Jarvis
final sendMessageProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final jarvisService = ref.watch(jarvisServiceProvider);
  final chatSessionService = ref.watch(chatSessionServiceProvider);
  final isar = ref.watch(isarProvider);

  return ChatNotifier(
    jarvisService: jarvisService,
    chatSessionService: chatSessionService,
    isar: isar,
  );
});

// State pour le chat
class ChatState {
  final bool isLoading;
  final String? error;

  ChatState({
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier pour gérer l'envoi de messages
class ChatNotifier extends StateNotifier<ChatState> {
  final JarvisService _jarvisService;
  final ChatSessionService _chatSessionService;
  final Isar _isar;

  ChatNotifier({
    required JarvisService jarvisService,
    required ChatSessionService chatSessionService,
    required Isar isar,
  })  : _jarvisService = jarvisService,
        _chatSessionService = chatSessionService,
        _isar = isar,
        super(ChatState());

  // Charger une liste de messages (pour l'historique)
  Future<void> loadMessages(List<ChatMessage> messages) async {
    // Vider la table locale (affichage)
    await _isar.writeTxn(() async {
      await _isar.chatMessages.clear();
      
      // Insérer les nouveaux messages
      if (messages.isNotEmpty) {
        await _isar.chatMessages.putAll(messages);
      }
    });

    // Mettre à jour l'historique de JarvisService
    _jarvisService.resetConversation();
    // TODO: Idéalement, on devrait aussi restaurer le contexte de Jarvis
    // Pour l'instant on le reset pour éviter les incohérences
  }

  // Envoyer un message
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Sauvegarder le message de l'utilisateur (affichage local)
      final userMessage = ChatMessage.user(message);
      await _isar.writeTxn(() async {
        await _isar.chatMessages.put(userMessage);
      });

      // 2. Ajouter à la session active (persistance historique)
      final activeSession = await _chatSessionService.getActiveSession();
      if (activeSession != null) {
        final sessionMessage = session_model.ChatMessage.user(message);
        await _chatSessionService.addMessageToSession(activeSession.id, sessionMessage);

        // Mettre à jour le titre si c'est le premier message
        if (activeSession.messageCount == 1) {
          _chatSessionService.updateSessionTitle(activeSession.id);
        }
      }

      // 3. Ajouter un indicateur de typing
      final typingMessage = ChatMessage.typing();
      await _isar.writeTxn(() async {
        await _isar.chatMessages.put(typingMessage);
      });

      // 4. Envoyer à Jarvis
      final response = await _jarvisService.sendMessage(message);

      // 5. Supprimer le typing indicator
      await _isar.writeTxn(() async {
        await _isar.chatMessages.delete(typingMessage.id);
      });

      // 6. Sauvegarder la réponse de Jarvis (affichage local)
      final assistantMessage = ChatMessage.assistant(response);
      await _isar.writeTxn(() async {
        await _isar.chatMessages.put(assistantMessage);
      });

      // 7. Ajouter à la session active (persistance historique)
      if (activeSession != null) {
        final sessionMessage = session_model.ChatMessage.assistant(response);
        await _chatSessionService.addMessageToSession(activeSession.id, sessionMessage);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Supprimer le typing indicator en cas d'erreur
      final messages = await _isar.chatMessages
          .filter()
          .isTypingEqualTo(true)
          .findAll();

      for (final msg in messages) {
        await _isar.writeTxn(() async {
          await _isar.chatMessages.delete(msg.id);
        });
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      // Sauvegarder un message d'erreur
      final errorMessage = ChatMessage.assistant(
        '❌ Désolé, une erreur s\'est produite : $e',
      );
      await _isar.writeTxn(() async {
        await _isar.chatMessages.put(errorMessage);
      });
    }
  }

  // Réinitialiser la conversation
  Future<void> resetConversation() async {
    _jarvisService.resetConversation();

    // Supprimer tous les messages locaux
    await _isar.writeTxn(() async {
      await _isar.chatMessages.clear();
    });

    // Ajouter un message de bienvenue
    final welcomeMessage = ChatMessage.assistant(
      '👋 Bonjour ! Je suis votre Assistant La Poste. Comment puis-je vous aider avec vos emails aujourd\'hui ?',
    );

    await _isar.writeTxn(() async {
      await _isar.chatMessages.put(welcomeMessage);
    });
    
    // Note: On ne crée pas de session ici, elle sera créée au premier message
    // ou manuellement via createAndActivateSession

    state = ChatState();
  }

  // Initialiser avec un message de bienvenue si vide
  Future<void> initializeIfEmpty() async {
    final count = await _isar.chatMessages.count();

    if (count == 0) {
      // Vérifier s'il y a une session active à restaurer
      final activeSession = await _chatSessionService.getActiveSession();
      if (activeSession != null) {
        final sessionMessages = activeSession.getMessages();
        if (sessionMessages.isNotEmpty) {
           // Convertir les messages de session en messages Isar
           final chatMessages = sessionMessages.map((m) {
             return m.role == 'user'
               ? ChatMessage.user(m.content)
               : ChatMessage.assistant(m.content);
           }).toList();
           await loadMessages(chatMessages);
           return;
        }
      }
    
      final welcomeMessage = ChatMessage.assistant(
        '👋 Bonjour ! Je suis votre Assistant La Poste.\n\nJe peux vous aider à :\n• Lire vos emails\n• Rechercher des messages\n• Envoyer et répondre à des emails\n• Supprimer des emails\n• Analyser l\'importance de vos messages\n\nQue puis-je faire pour vous ?',
      );

      await _isar.writeTxn(() async {
        await _isar.chatMessages.put(welcomeMessage);
      });
      
      // Si pas de session, on en crée une nouvelle
      if (activeSession == null) {
         final sessionWelcome = session_model.ChatMessage.assistant(
           '👋 Bonjour ! Je suis votre Assistant La Poste.\n\nJe peux vous aider à :\n• Lire vos emails\n• Rechercher des messages\n• Envoyer et répondre à des emails\n• Supprimer des emails\n• Analyser l\'importance de vos messages\n\nQue puis-je faire pour vous ?',
         );
         await _chatSessionService.createAndActivateSession(
           initialMessages: [sessionWelcome]
         );
      }
    }
  }
}
