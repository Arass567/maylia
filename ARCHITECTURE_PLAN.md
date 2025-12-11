# 🏗️ PLAN D'ACTION ARCHITECTURALE - Smart Mail La Poste

> **Lead Architect** : Refactoring IMAP + UI/UX ChatGPT-like
> **Date** : 8 Décembre 2025
> **Priority** : 🔴 CRITIQUE

---

## 📋 DIAGNOSTIC COMPLET

### 🔴 PROBLÈME 1 : Architecture IMAP (CRITIQUE)

#### Bugs Identifiés (Screenshots 1-3)

```
❌ LateInitializationError: Field '_serverInfo@1383481704' has not been initialized
❌ TimeoutException after 0:00:20.000000: Future not completed
❌ Drawer "Dossiers" vide - Aucun dossier récupéré
⚠️  Seul INBOX accessible (pas d'archives, sous-dossiers)
```

#### Causes Racines

1. **`EmailService.getMailboxes()` (ligne 99-116)**
   - Utilise `listMailboxes()` sans paramètres
   - Pas de gestion récursive des sous-dossiers
   - Ne récupère que les dossiers racine (INBOX, Sent, Trash)
   - **MANQUE** : Les archives et dossiers personnalisés

2. **Timeout 20s trop court**
   - La Poste IMAP peut être lent
   - Le provider appelle avec `.timeout(Duration(seconds: 20))`
   - Besoin d'augmenter à 60s minimum

3. **`_serverInfo` non initialisé**
   - Erreur dans `ImapClient` de `enough_mail`
   - Se produit quand `connectImap()` échoue silencieusement
   - Le client n'est pas dans un état valide

---

### 🎨 PROBLÈME 2 : UI Chat Basique (Screenshot 4)

#### État Actuel
- ✅ Interface fonctionnelle
- ❌ Conversation éphémère (perdue au redémarrage)
- ❌ Pas de drawer historique
- ❌ Pas de titres auto-générés
- ❌ Design basique (pas d'animations)

#### Objectif : ChatGPT-like
- Persistance complète dans Isar
- Drawer latéral avec liste des conversations
- Titres intelligents générés par Claude
- Animations de typing
- Design moderne (bulles, glassmorphism)

---

## 🛠️ PLAN D'IMPLÉMENTATION

### PHASE 1 : 🔴 FIX IMAP ARCHITECTURE (PRIORITÉ MAX)

#### 1.1 - Refactoring `EmailService.getMailboxes()`

**Fichier** : `lib/services/email_service.dart`

**Modifications** :

```dart
// AVANT (ligne 99-116) - NE récupère QUE les dossiers racine
Future<List<Mailbox>> getMailboxes() async {
  await connectImap();
  final mailboxes = await _imapClient!.listMailboxes();
  return mailboxes;
}

// APRÈS - Récupération RÉCURSIVE complète
Future<List<Mailbox>> getMailboxes() async {
  await connectImap();

  try {
    // 1. Récupérer TOUS les dossiers avec wildcard recursif
    final mailboxes = await _imapClient!.listMailboxes(
      recursive: true,
      path: '',  // Racine
    );

    // 2. Fallback : Si recursive ne fonctionne pas, utiliser "*"
    if (mailboxes.isEmpty) {
      final allBoxes = await _imapClient!.list('*', '');
      return allBoxes;
    }

    // 3. Filtrer les dossiers système invisibles
    return mailboxes.where((m) {
      return !m.flags.contains(MailboxFlag.noSelect) &&
             !m.name.startsWith('[Gmail]');
    }).toList();

  } catch (e) {
    print('❌ Erreur récupération dossiers: $e');
    rethrow;
  }
}

// NOUVEAU : Fonction helper pour scan récursif manuel
Future<List<Mailbox>> _getAllMailboxesRecursive(
  String parentPath,
) async {
  final List<Mailbox> allMailboxes = [];

  try {
    // Liste des enfants directs
    final children = await _imapClient!.listMailboxes(
      path: parentPath,
      recursive: false,
    );

    for (final mailbox in children) {
      allMailboxes.add(mailbox);

      // Si le dossier a des enfants, récursion
      if (!mailbox.flags.contains(MailboxFlag.noInferiors)) {
        final subMailboxes = await _getAllMailboxesRecursive(
          mailbox.path,
        );
        allMailboxes.addAll(subMailboxes);
      }
    }
  } catch (e) {
    print('⚠️ Erreur scan récursif $parentPath: $e');
  }

  return allMailboxes;
}
```

**Test** :
```dart
final boxes = await emailService.getMailboxes();
print('📂 ${boxes.length} dossiers récupérés');
for (var box in boxes) {
  print('  - ${box.name} (${box.path})');
}
```

---

#### 1.2 - Augmenter Timeout IMAP

**Fichier** : `lib/providers/email_providers.dart`

**Ligne 231-256** : `mailboxesProvider`

```dart
// AVANT
final mailboxesProvider = FutureProvider<List<MailboxModel>>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  final imapMailboxes = await emailService.getMailboxes(); // Timeout par défaut
  // ...
});

// APRÈS - Ajouter timeout explicite de 60s
final mailboxesProvider = FutureProvider<List<MailboxModel>>((ref) async {
  final emailService = ref.watch(emailServiceProvider);

  final imapMailboxes = await emailService.getMailboxes()
    .timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException(
          'Impossible de récupérer les dossiers après 60s. Vérifiez votre connexion.',
        );
      },
    );

  // Convertir en MailboxModel...
});
```

---

#### 1.3 - Fix `connectImap()` avec retry

**Fichier** : `lib/services/email_service.dart`

**Ligne 19-70** : Ajouter retry mechanism

```dart
Future<void> connectImap({int maxRetries = 3}) async {
  if (_imapClient != null && _imapClient!.isLoggedIn) {
    return;
  }

  if (_imapConnectingCompleter != null) {
    return _imapConnectingCompleter!.future;
  }

  _imapConnectingCompleter = Completer<void>();

  int attempt = 0;
  Exception? lastError;

  while (attempt < maxRetries) {
    try {
      attempt++;
      print('🔌 Tentative connexion IMAP $attempt/$maxRetries...');

      if (_imapClient != null) {
        try {
          await _imapClient!.logout();
        } catch (_) {}
      }

      _imapClient = ImapClient(isLogEnabled: false);

      // Timeout de 30s par tentative
      await _imapClient!.connectToServer(
        _imapHost,
        _imapPort,
        isSecure: true,
      ).timeout(const Duration(seconds: 30));

      await _imapClient!.login(_email, _password)
        .timeout(const Duration(seconds: 20));

      print('✅ Connexion IMAP réussie (tentative $attempt)');
      _imapConnectingCompleter!.complete();
      return;

    } catch (e) {
      lastError = e as Exception;
      print('❌ Erreur connexion IMAP (tentative $attempt): $e');

      if (attempt < maxRetries) {
        // Attendre avant de réessayer (backoff exponentiel)
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  // Si toutes les tentatives échouent
  _imapConnectingCompleter!.completeError(lastError!);
  _imapClient = null;
  _imapConnectingCompleter = null;
  throw lastError!;
}
```

---

### PHASE 2 : 🎨 CHAT UI CHATGPT-LIKE

#### 2.1 - Créer Modèle `ChatSession`

**Nouveau fichier** : `lib/models/chat_session.dart`

```dart
import 'package:isar/isar.dart';

part 'chat_session.g.dart';

@collection
class ChatSession {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;

  // Titre de la conversation (généré par IA ou par date)
  late String title;

  // Historique des messages (JSON serialisé)
  late String messagesJson; // List<Map<String, dynamic>>

  // Nombre de messages dans la session
  late int messageCount;

  // Dernière réponse de l'IA
  String? lastMessage;

  ChatSession();

  factory ChatSession.create({
    required String title,
    required String messagesJson,
    required int messageCount,
    String? lastMessage,
  }) {
    return ChatSession()
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..title = title
      ..messagesJson = messagesJson
      ..messageCount = messageCount
      ..lastMessage = lastMessage;
  }
}
```

**Générer** :
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

#### 2.2 - Persistance Chat dans `main.dart`

**Fichier** : `lib/main.dart`

**Ajouter** dans `IsarProvider` :

```dart
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar must be initialized in main()');
});

// Dans main()
Future<void> main() async {
  // ...
  final isar = await Isar.open([
    EmailModelSchema,
    ChatMessageSchema,
    TrustedSenderSchema,
    MailboxModelSchema,
    ChatSessionSchema, // ✅ AJOUTER
  ], directory: dir.path);
  // ...
}
```

---

#### 2.3 - Service `ChatSessionService`

**Nouveau fichier** : `lib/services/chat_session_service.dart`

```dart
import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import 'ai_service.dart';

class ChatSessionService {
  final Isar _isar;
  final AiService _aiService;

  ChatSessionService(this._isar, this._aiService);

  // Créer une nouvelle session
  Future<ChatSession> createSession({
    required List<ChatMessage> messages,
  }) async {
    // Générer un titre intelligent avec l'IA
    final title = await _generateSessionTitle(messages);

    final session = ChatSession.create(
      title: title,
      messagesJson: jsonEncode(
        messages.map((m) => {
          'role': m.role.name,
          'content': m.content,
          'timestamp': m.timestamp.toIso8601String(),
        }).toList(),
      ),
      messageCount: messages.length,
      lastMessage: messages.isNotEmpty ? messages.last.content : null,
    );

    await _isar.writeTxn(() async {
      await _isar.chatSessions.put(session);
    });

    return session;
  }

  // Récupérer toutes les sessions
  Future<List<ChatSession>> getAllSessions() async {
    return _isar.chatSessions
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
  }

  // Mettre à jour une session
  Future<void> updateSession({
    required int sessionId,
    required List<ChatMessage> messages,
  }) async {
    final session = await _isar.chatSessions.get(sessionId);
    if (session == null) return;

    session.messagesJson = jsonEncode(
      messages.map((m) => {
        'role': m.role.name,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
    );
    session.messageCount = messages.length;
    session.updatedAt = DateTime.now();
    session.lastMessage = messages.isNotEmpty ? messages.last.content : null;

    await _isar.writeTxn(() async {
      await _isar.chatSessions.put(session);
    });
  }

  // Supprimer une session
  Future<void> deleteSession(int sessionId) async {
    await _isar.writeTxn(() async {
      await _isar.chatSessions.delete(sessionId);
    });
  }

  // Générer un titre intelligent
  Future<String> _generateSessionTitle(List<ChatMessage> messages) async {
    if (messages.isEmpty) {
      return 'Nouvelle conversation';
    }

    try {
      // Prendre les 3 premiers messages
      final preview = messages.take(3).map((m) => m.content).join(' ');

      // Demander à l'IA de générer un titre court
      final prompt = '''Génère un titre court (max 6 mots) pour cette conversation :
"$preview"

Réponds UNIQUEMENT avec le titre, sans guillemets ni ponctuation.''';

      final title = await _aiService.callClaude(prompt);
      return title.trim().substring(0, 50); // Limiter à 50 chars
    } catch (e) {
      // Fallback : utiliser la date
      return 'Conversation ${DateTime.now().day}/${DateTime.now().month}';
    }
  }

  // Charger les messages d'une session
  List<ChatMessage> loadMessagesFromSession(ChatSession session) {
    final messagesData = jsonDecode(session.messagesJson) as List;

    return messagesData.map((data) {
      return ChatMessage(
        role: data['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        content: data['content'],
        timestamp: DateTime.parse(data['timestamp']),
      );
    }).toList();
  }
}
```

---

#### 2.4 - Drawer Historique Chat

**Nouveau fichier** : `lib/widgets/chat_history_drawer.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_session.dart';
import '../providers/chat_providers.dart';
import 'package:intl/intl.dart';

class ChatHistoryDrawer extends ConsumerWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Drawer(
      child: Column(
        children: [
          // Header avec glassmorphism
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Historique',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // Créer nouvelle conversation
                        ref.read(currentSessionIdProvider.notifier).state = null;
                        ref.read(chatHistoryProvider.notifier).clear();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        'Nouvelle conversation',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Liste des sessions
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune conversation',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final currentSessionId = ref.watch(currentSessionIdProvider);
                    final isSelected = session.id == currentSessionId;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.1),
                      leading: Icon(
                        Icons.chat_bubble_outline,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${session.messageCount} messages • ${_formatDate(session.updatedAt)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Supprimer ?'),
                              content: Text(
                                  'Voulez-vous supprimer cette conversation ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: Text('Supprimer'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(chatSessionServiceProvider)
                                .deleteSession(session.id);
                            ref.invalidate(chatSessionsProvider);
                          }
                        },
                      ),
                      onTap: () {
                        // Charger la session
                        ref.read(currentSessionIdProvider.notifier).state =
                            session.id;
                        ref
                            .read(chatHistoryProvider.notifier)
                            .loadFromSession(session);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Erreur: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} jours';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
```

---

#### 2.5 - Animations Typing

**Fichier** : `lib/screens/chat_screen.dart`

Ajouter un widget pour l'animation :

```dart
class TypingIndicator extends StatefulWidget {
  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (math.sin(value * math.pi)).clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
```

---

### PHASE 3 : 🎨 UI/UX TRENDS 2025

#### 3.1 - Glassmorphism sur Chat Header

**Fichier** : `lib/screens/chat_screen.dart`

```dart
import 'dart:ui'; // Pour BackdropFilter

// Dans le AppBar
AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  flexibleSpace: ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.3),
              Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
      ),
    ),
  ),
  // ...
)
```

---

#### 3.2 - Micro-interactions sur Boutons

**Fichier** : `lib/widgets/animated_send_button.dart`

```dart
class AnimatedSendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const AnimatedSendButton({
    required this.onPressed,
    required this.isLoading,
    super.key,
  });

  @override
  State<AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<AnimatedSendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.send, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 📊 RÉCAPITULATIF

### Problèmes Résolus

| Problème | Solution | Fichiers Modifiés |
|----------|----------|-------------------|
| 🔴 IMAP Dossiers incomplets | Scan récursif + wildcard | `email_service.dart` |
| 🔴 Timeout 20s | Augmenté à 60s + retry | `email_service.dart`, `email_providers.dart` |
| 🔴 `_serverInfo` error | Retry mechanism + error handling | `email_service.dart` |
| 🎨 Chat éphémère | Persistance Isar `ChatSession` | `chat_session.dart` (nouveau) |
| 🎨 Pas d'historique | Drawer avec liste sessions | `chat_history_drawer.dart` (nouveau) |
| 🎨 UI basique | Glassmorphism + animations | `chat_screen.dart`, widgets nouveaux |

---

## ✅ CHECKLIST D'IMPLÉMENTATION

### Backend IMAP
- [ ] Refactorer `getMailboxes()` avec scan récursif
- [ ] Ajouter fonction `_getAllMailboxesRecursive()`
- [ ] Augmenter timeout à 60s dans providers
- [ ] Ajouter retry mechanism dans `connectImap()`
- [ ] Tester avec compte La Poste réel

### Chat Persistant
- [ ] Créer modèle `ChatSession`
- [ ] Générer avec build_runner
- [ ] Créer `ChatSessionService`
- [ ] Créer `ChatHistoryDrawer`
- [ ] Modifier `chat_screen.dart` pour persistance
- [ ] Ajouter provider `currentSessionIdProvider`

### UI/UX 2025
- [ ] Glassmorphism sur AppBar chat
- [ ] Animation typing indicator
- [ ] Micro-interactions bouton send
- [ ] Transitions fluides entre sessions

---

## 🚀 ORDRE D'EXÉCUTION

1. **IMMÉDIAT** : Fix IMAP (Phase 1) - 2h
2. **AUJOURD'HUI** : Chat persistant (Phase 2) - 3h
3. **DEMAIN** : UI/UX polish (Phase 3) - 2h

**TOTAL ESTIMÉ** : 7 heures de développement

---

*Document généré par Lead Architect - Smart Mail La Poste*
