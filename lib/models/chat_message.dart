import 'package:isar/isar.dart';

part 'chat_message.g.dart';

enum MessageRole {
  user,
  assistant,
  system,
}

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late MessageRole role;

  late String content;
  late DateTime timestamp;

  // Pour les messages avec actions (ex: liste d'emails)
  String? metadata; // JSON pour stocker des données supplémentaires

  // Pour le typing indicator
  bool isTyping = false;

  ChatMessage();

  factory ChatMessage.create({
    required MessageRole role,
    required String content,
    String? metadata,
    bool isTyping = false,
  }) {
    return ChatMessage()
      ..role = role
      ..content = content
      ..timestamp = DateTime.now()
      ..metadata = metadata
      ..isTyping = isTyping;
  }

  factory ChatMessage.user(String content) {
    return ChatMessage.create(
      role: MessageRole.user,
      content: content,
    );
  }

  factory ChatMessage.assistant(String content, {String? metadata}) {
    return ChatMessage.create(
      role: MessageRole.assistant,
      content: content,
      metadata: metadata,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage.create(
      role: MessageRole.system,
      content: content,
    );
  }

  factory ChatMessage.typing() {
    return ChatMessage.create(
      role: MessageRole.assistant,
      content: '',
      isTyping: true,
    );
  }
}
