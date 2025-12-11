import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart' as session_model;
import '../providers/chat_providers.dart';
import '../providers/chat_session_providers.dart';
import '../widgets/chat_history_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation pour Jarvis
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialiser le chat si vide
    Future.microtask(() {
      ref.read(sendMessageProvider.notifier).initializeIfEmpty();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _buildMessageSemanticLabel(ChatMessage message) {
    final sender = message.role == MessageRole.user ? 'Vous' : 'JARVIS';
    final time = DateFormat('HH:mm').format(message.timestamp);
    return '$sender à $time: ${message.content}';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Haptic feedback
    HapticFeedback.lightImpact();

    ref.read(sendMessageProvider.notifier).sendMessage(message);

    _scrollToBottom();
  }

  void _loadSession(session_model.ChatSession session) async {
    // Charger les messages de la session
    final messages = session.getMessages();

    // Convertir en ChatMessage et mettre à jour le provider
    final chatMessages = messages.map((m) {
      return ChatMessage.create(
        content: m.content,
        role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
      );
    }).toList();

    // Réinitialiser avec les messages de la session
    ref.read(sendMessageProvider.notifier).loadMessages(chatMessages);

    HapticFeedback.lightImpact();
  }

  void _startNewChat() async {
    // Créer une nouvelle session
    final service = ref.read(chatSessionServiceProvider);
    await service.createAndActivateSession();

    // Réinitialiser le chat
    ref.read(sendMessageProvider.notifier).resetConversation();

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final chatState = ref.watch(sendMessageProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Adaptatif light/dark
      // Drawer d'historique ChatGPT-like
      drawer: ChatHistoryDrawer(
        onSessionSelected: _loadSession,
        onNewChat: _startNewChat,
      ),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Historique des conversations',
          ),
        ),
        title: Row(
          children: [
            // Avatar Assistant (simple, sans pulsation)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700), // Jaune La Poste
              ),
              child: const Icon(
                Icons.auto_awesome, // Étincelle
                color: Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistant IA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Afficher le titre de la session active
                  activeSessionAsync.when(
                    data: (session) => Text(
                      session?.title ?? 'Votre messagerie intelligente',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Text(
                      'Votre messagerie intelligente',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Votre messagerie intelligente',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Réinitialiser la conversation',
            child: IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
              onPressed: () async {
                HapticFeedback.mediumImpact();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: theme.colorScheme.surface,
                  title: Text(
                    'Réinitialiser',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  content: Text(
                    'Voulez-vous effacer toute la conversation ?',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                HapticFeedback.heavyImpact();
                ref.read(sendMessageProvider.notifier).resetConversation();
              }
            },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700), // Jaune La Poste
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    if (message.isTyping) {
                      return _TypingIndicator();
                    }

                    return Semantics(
                      liveRegion: true,
                      label: _buildMessageSemanticLabel(message),
                      child: _MessageBubble(
                        message: message,
                        isUser: message.role == MessageRole.user,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Erreur: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

          // Champ de saisie
          _buildInputField(chatState),
        ],
      ),
    );
  }

  Widget _buildInputField(ChatState chatState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Semantics(
                label: 'Zone de texte pour envoyer un message à l\'assistant',
                textField: true,
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Demandez quelque chose...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !chatState.isLoading,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bouton envoyer
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700), // Jaune La Poste
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Semantics(
              button: true,
              label: chatState.isLoading ? 'Envoi en cours' : 'Envoyer le message',
              child: IconButton(
                icon: chatState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.black87),
                onPressed: chatState.isLoading ? null : _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Bulle de message
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _MessageBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar Assistant
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD700), // Jaune La Poste
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.black87,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Bulle de texte
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFFFF9E6))
                    : (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFFFFD700).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // Avatar utilisateur
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF3A3A4E) : const Color(0xFF1A1A2E),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Indicateur de typing
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Assistant
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFD700), // Jaune La Poste
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.black87,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          // Animation typing
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.3;
                    final value =
                        ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
                    final opacity = (value < 0.5
                        ? value * 2
                        : (1 - value) * 2);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFD700).withOpacity(opacity),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
