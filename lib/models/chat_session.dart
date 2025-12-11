import 'package:isar/isar.dart';
import 'dart:convert';

part 'chat_session.g.dart';

/// Modèle pour stocker une session de conversation avec JARVIS
/// Permet de garder l'historique complet des conversations
@collection
class ChatSession {
  Id id = Isar.autoIncrement;

  /// Date de création de la session
  late DateTime createdAt;

  /// Dernière modification
  late DateTime updatedAt;

  /// Titre de la conversation (généré par l'IA ou basé sur date)
  late String title;

  /// Messages sérialisés en JSON
  /// Structure: [{"role": "user|assistant", "content": "...", "timestamp": "..."}]
  late String messagesJson;

  /// Nombre de messages dans la session
  @Index()
  late int messageCount;

  /// Dernier message (pour prévisualisation dans la liste)
  String? lastMessage;

  /// Preview du dernier message (tronqué à 100 caractères)
  String? lastMessagePreview;

  /// Si la session est active (conversation en cours)
  @Index()
  late bool isActive;

  /// Constructeur par défaut
  ChatSession();

  /// Créer une nouvelle session
  static ChatSession create({
    String? title,
    List<ChatMessage>? initialMessages,
  }) {
    final session = ChatSession()
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..title = title ?? 'Nouvelle conversation'
      ..messageCount = initialMessages?.length ?? 0
      ..isActive = true;

    if (initialMessages != null && initialMessages.isNotEmpty) {
      session.messagesJson = _serializeMessages(initialMessages);
      session.lastMessage = initialMessages.last.content;
      session.lastMessagePreview = _truncatePreview(initialMessages.last.content);
    } else {
      session.messagesJson = '[]';
      session.lastMessage = null;
      session.lastMessagePreview = null;
    }

    return session;
  }

  /// Désérialiser les messages
  List<ChatMessage> getMessages() {
    if (messagesJson.isEmpty || messagesJson == '[]') {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(messagesJson);
      return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('⚠️ Erreur désérialisation messages: $e');
      return [];
    }
  }

  /// Ajouter un message à la session
  void addMessage(ChatMessage message) {
    final currentMessages = getMessages();
    currentMessages.add(message);

    messagesJson = _serializeMessages(currentMessages);
    messageCount = currentMessages.length;
    lastMessage = message.content;
    lastMessagePreview = _truncatePreview(message.content);
    updatedAt = DateTime.now();
  }

  /// Remplacer tous les messages
  void setMessages(List<ChatMessage> messages) {
    messagesJson = _serializeMessages(messages);
    messageCount = messages.length;

    if (messages.isNotEmpty) {
      lastMessage = messages.last.content;
      lastMessagePreview = _truncatePreview(messages.last.content);
    } else {
      lastMessage = null;
      lastMessagePreview = null;
    }

    updatedAt = DateTime.now();
  }

  /// Générer un titre automatique basé sur le premier message utilisateur
  String generateAutoTitle() {
    final messages = getMessages();
    final firstUserMessage = messages.firstWhere(
      (m) => m.role == 'user',
      orElse: () => ChatMessage(
        role: 'user',
        content: 'Conversation',
        timestamp: DateTime.now(),
      ),
    );

    // Tronquer à 50 caractères max
    final content = firstUserMessage.content;
    if (content.length <= 50) {
      return content;
    }

    return '${content.substring(0, 47)}...';
  }

  /// Sérialiser une liste de messages en JSON
  static String _serializeMessages(List<ChatMessage> messages) {
    final jsonList = messages.map((m) => m.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Tronquer le preview à 100 caractères
  static String _truncatePreview(String text) {
    if (text.length <= 100) {
      return text;
    }
    return '${text.substring(0, 97)}...';
  }
}

/// Message individuel dans une conversation
class ChatMessage {
  final String role; // 'user' ou 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Créer depuis JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Créer un message utilisateur
  static ChatMessage user(String content) {
    return ChatMessage(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Créer un message assistant
  static ChatMessage assistant(String content) {
    return ChatMessage(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }
}
