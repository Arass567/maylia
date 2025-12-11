import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/chat_session.dart';
import '../services/chat_session_service.dart';
import '../services/ai_service.dart';
import 'email_providers.dart';

/// Provider pour ChatSessionService
final chatSessionServiceProvider = Provider<ChatSessionService>((ref) {
  final isar = ref.watch(isarProvider);
  final aiService = ref.watch(aiServiceProvider);

  return ChatSessionService(
    isar: isar,
    aiService: aiService,
  );
});

/// Provider pour la session active actuelle
final activeSessionProvider = FutureProvider<ChatSession?>((ref) async {
  final service = ref.watch(chatSessionServiceProvider);
  return await service.getActiveSession();
});

/// Provider pour toutes les sessions (historique)
final allSessionsProvider = FutureProvider<List<ChatSession>>((ref) async {
  final service = ref.watch(chatSessionServiceProvider);
  return await service.getAllSessions();
});

/// Provider pour créer une nouvelle session
final createSessionProvider = FutureProvider.family<ChatSession, String?>((ref, title) async {
  final service = ref.watch(chatSessionServiceProvider);

  return await service.createAndActivateSession(
    title: title ?? 'Nouvelle conversation',
  );
});

/// Provider pour charger une session existante
final loadSessionProvider = FutureProvider.family<ChatSession?, int>((ref, sessionId) async {
  final service = ref.watch(chatSessionServiceProvider);

  // Activer la session
  await service.activateSession(sessionId);

  // Retourner la session
  return await service.getSession(sessionId);
});

/// Provider pour générer un titre intelligent
final generateTitleProvider = FutureProvider.family<String, int>((ref, sessionId) async {
  final service = ref.watch(chatSessionServiceProvider);

  await service.updateSessionTitle(sessionId);

  final session = await service.getSession(sessionId);
  return session?.title ?? 'Conversation';
});

/// Provider pour supprimer une session
final deleteSessionProvider = FutureProvider.family<void, int>((ref, sessionId) async {
  final service = ref.watch(chatSessionServiceProvider);

  await service.deleteSession(sessionId);
});

/// Provider pour le nombre de sessions
final sessionCountProvider = StreamProvider<int>((ref) {
  final isar = ref.watch(isarProvider);

  return isar.chatSessions
      .watchLazy()
      .asyncMap((_) => isar.chatSessions.count());
});
