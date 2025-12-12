import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart' as session_model;
import '../providers/chat_providers.dart';
import '../providers/chat_session_providers.dart';
import '../theme/app_theme_2025.dart';
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
      // Drawer d'historique ChatGPT-like
      drawer: ChatHistoryDrawer(
        onSessionSelected: _loadSession,
        onNewChat: _startNewChat,
      ),
      appBar: AppBar(
        backgroundColor: AppTheme2025.goldenYellow,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assistant IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser la conversation',
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Réinitialiser la conversation ?'),
                  content: const Text(
                      'Cela effacera l\'historique de la session actuelle.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
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
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/chat_background.jpg'),
            repeat: ImageRepeat.repeat,
            opacity: 0.1, // Très léger pour ne pas gêner la lecture
          ),
        ),
        child: Column(
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
      ),
    );
  }

  Widget _buildInputField(ChatState chatState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Use the scaffold background color
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea( // To avoid system intrusions at the bottom
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor, // White
                  borderRadius: BorderRadius.circular(AppTheme2025.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Envoyer un message...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 5, // Allow multiple lines
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !chatState.isLoading,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send Button
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme2025.antwarpBlue,
              child: IconButton(
                icon: chatState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: chatState.isLoading ? null : _sendMessage,
                tooltip: 'Envoyer',
              ),
            ),
          ],
        ),
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

    // New colors from the mockup
    final userBubbleColor = isDark ? const Color(0xFF2A3740) : Colors.white;
    final assistantBubbleColor = isDark ? const Color(0xFF2A3740) : AppTheme2025.slateColor;
    final assistantTextColor = isDark ? Colors.white.withOpacity(0.9) : Colors.white;
    final userTextColor = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom
        children: [
          if (!isUser) ...[
            // Assistant Avatar
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme2025.antwarpBlue,
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : assistantBubbleColor,
                borderRadius: BorderRadius.circular(AppTheme2025.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? userTextColor : assistantTextColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            // User Avatar
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/user_avatar.jpg'),
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
