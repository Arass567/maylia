# Plan de Transformation : Super App La Poste "Hybrid UI"

## Vision

Transformer l'application actuelle (thème Jarvis/Iron Man) en une **Super App La Poste professionnelle** avec :
- Design clean et minimaliste (Blanc/Jaune La Poste)
- Navigation complète entre dossiers IMAP (Inbox, Sent, Trash, Spam, Archive, etc.)
- Assistant IA capable d'interagir avec tous les dossiers
- Interface hybride : Email classique + ChatGPT-style

---

## État Actuel vs État Cible

### Architecture Actuelle ✅
- BottomNavigationBar avec 2 onglets (JARVIS, Inbox)
- Riverpod + Isar + enough_mail
- Claude Sonnet 4.5 avec 8 tools
- Design Jarvis (bleu #00D9FF, cyan, gradients néon)
- **Limitation** : Accès uniquement à INBOX

### Architecture Cible 🎯
- BottomNavigationBar avec 2 onglets (Emails, Assistant)
- Même stack technique (Riverpod + Isar + enough_mail)
- Design La Poste (blanc #FFFFFF, jaune #FFD700)
- **Nouveau** : Accès à tous les dossiers IMAP
- **Nouveau** : Assistant IA peut naviguer entre dossiers

---

## Plan d'Implémentation

### 🎨 Phase 1 : Refonte Design System (2h)

**Objectif** : Remplacer le thème Jarvis par le design La Poste clean

#### 1.1 Modifier `app_theme_2025.dart`
- **Couleurs principales** :
  - Blanc pur : `#FFFFFF`
  - Gris clair : `#F5F5F5` (background secondaire)
  - Jaune La Poste : `#FFD700` (accent)
  - Bleu Nuit : `#1A1A2E` (texte/contraste)
- **Supprimer** : Toutes les couleurs Jarvis (cyan, blue néon)
- **Conserver** : Les couleurs sémantiques (success, warning, error) et les couleurs d'importance

#### 1.2 Adapter `chat_screen.dart`
- Supprimer le background `#0A0E27` (bleu foncé) → `#FFFFFF`
- Supprimer les gradients néon cyan/bleu
- Bulles utilisateur : Fond jaune pâle `#FFF9E6`
- Bulles IA : Fond gris clair `#F5F5F5`
- Texte : Bleu nuit `#1A1A2E`
- Supprimer l'animation de pulsation du logo Jarvis
- Remplacer l'icône `psychology` par `auto_awesome` (étincelle)

#### 1.3 Adapter `inbox_screen.dart`
- Conserver la structure actuelle (déjà clean)
- S'assurer que les couleurs utilisent la nouvelle palette

#### 1.4 Modifier `home_screen.dart`
- Inverser l'ordre des onglets :
  - **Onglet 0** : Emails (icône `mail`, label "Emails")
  - **Onglet 1** : Assistant (icône `auto_awesome`, label "Assistant")
- Changer le label "JARVIS" → "Assistant"

---

### 📧 Phase 2 : Gestion Complète des Dossiers IMAP (3h)

**Objectif** : Permettre l'accès à tous les dossiers (Inbox, Sent, Trash, Spam, Archive, etc.)

#### 2.1 Améliorer `email_service.dart`

**Ajouter les méthodes** :

```dart
// 1. Récupérer la liste de tous les dossiers IMAP
Future<List<Mailbox>> getMailboxes() async {
  await connectImap();
  return await _imapClient!.listMailboxes();
}

// 2. Sélectionner un dossier spécifique
Future<Mailbox> selectMailbox(String path) async {
  await connectImap();
  return await _imapClient!.selectMailbox(path);
}

// 3. Récupérer les emails d'un dossier spécifique
Future<List<EmailModel>> fetchEmailsFromMailbox(String mailboxPath, {int limit = 50}) async {
  await connectImap();
  await selectMailbox(mailboxPath);

  // Même logique que fetchAllEmails mais sur le dossier sélectionné
  final fetchResult = await _imapClient!.fetchRecentMessages(
    messageCount: limit,
    criteria: 'BODY.PEEK[] FLAGS',
  );

  return fetchResult.messages.map(_parseEmailToModel).toList();
}

// 4. Déplacer un email vers un autre dossier
Future<void> moveEmail(int uid, String targetFolderPath) async {
  await connectImap();

  // Copier vers le dossier cible
  await _imapClient!.copy(
    MessageSequence.fromId(uid),
    targetMailboxPath: targetFolderPath,
  );

  // Supprimer l'original
  await deleteEmail(uid);
}
```

**Modifier les méthodes existantes** :
- Ajouter un paramètre optionnel `mailboxPath` à `fetchNewEmails()` et `fetchAllEmails()`
- Par défaut, utiliser 'INBOX'

#### 2.2 Créer un nouveau modèle `mailbox_model.dart`

```dart
import 'package:isar/isar.dart';

part 'mailbox_model.g.dart';

@collection
class MailboxModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String path;          // Ex: "INBOX", "Sent", "Spam"
  late String name;          // Nom d'affichage
  late int messageCount;     // Nombre de messages
  late int unseenCount;      // Nombre de non lus

  String? parentPath;        // Pour les dossiers imbriqués

  // Dossiers spéciaux (flags IMAP)
  bool isInbox = false;
  bool isSent = false;
  bool isTrash = false;
  bool isSpam = false;
  bool isDrafts = false;
  bool isArchive = false;

  DateTime? lastSync;

  static MailboxModel fromImapMailbox(Mailbox mailbox) {
    return MailboxModel()
      ..path = mailbox.path
      ..name = mailbox.name
      ..messageCount = mailbox.messagesExists
      ..unseenCount = mailbox.messagesUnseen
      ..isInbox = mailbox.isInbox
      ..isSent = mailbox.isSent
      ..isTrash = mailbox.isTrash
      ..isSpam = mailbox.isJunk
      ..isDrafts = mailbox.isDrafts
      ..isArchive = mailbox.isArchive;
  }
}
```

#### 2.3 Créer de nouveaux providers dans `email_providers.dart`

```dart
// Provider pour le dossier actuellement sélectionné
final currentMailboxProvider = StateProvider<String>((ref) => 'INBOX');

// Provider pour la liste des mailboxes
final mailboxesProvider = FutureProvider<List<MailboxModel>>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  final isar = ref.watch(isarProvider);

  // Récupérer depuis le serveur
  final imapMailboxes = await emailService.getMailboxes();

  // Convertir et sauvegarder dans Isar
  final mailboxModels = imapMailboxes.map(MailboxModel.fromImapMailbox).toList();

  await isar.writeTxn(() async {
    await isar.mailboxModels.clear();
    await isar.mailboxModels.putAll(mailboxModels);
  });

  return mailboxModels;
});

// Provider pour les emails du dossier actuel
final currentMailboxEmailsProvider = StreamProvider<List<EmailModel>>((ref) {
  final currentMailbox = ref.watch(currentMailboxProvider);
  final isar = ref.watch(isarProvider);

  // Stream des emails du dossier actuel
  return isar.emailModels
      .filter()
      .mailboxPathEqualTo(currentMailbox) // NOUVEAU CHAMP à ajouter dans EmailModel
      .sortByDateDesc()
      .watch(fireImmediately: true);
});
```

#### 2.4 Modifier `email_model.dart`

**Ajouter le champ** :
```dart
@Index()
String mailboxPath = 'INBOX'; // Dossier où se trouve l'email
```

---

### 📂 Phase 3 : Interface Navigation Dossiers (2h)

**Objectif** : Ajouter un Drawer pour naviguer entre dossiers

#### 3.1 Créer `widgets/mailbox_drawer.dart`

```dart
class MailboxDrawer extends ConsumerWidget {
  const MailboxDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mailboxesAsync = ref.watch(mailboxesProvider);
    final currentMailbox = ref.watch(currentMailboxProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary, // Jaune La Poste
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mail, size: 48, color: Colors.black87),
                SizedBox(height: 12),
                Text(
                  'Dossiers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Liste des dossiers
          Expanded(
            child: mailboxesAsync.when(
              data: (mailboxes) => ListView.builder(
                itemCount: mailboxes.length,
                itemBuilder: (context, index) {
                  final mailbox = mailboxes[index];
                  final isSelected = mailbox.path == currentMailbox;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Color(0xFFFFF9E6), // Jaune très pâle
                    leading: Icon(_getMailboxIcon(mailbox)),
                    title: Text(mailbox.name),
                    trailing: mailbox.unseenCount > 0
                        ? Badge(
                            label: Text('${mailbox.unseenCount}'),
                            backgroundColor: Colors.red,
                          )
                        : null,
                    onTap: () {
                      ref.read(currentMailboxProvider.notifier).state = mailbox.path;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              loading: () => Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMailboxIcon(MailboxModel mailbox) {
    if (mailbox.isInbox) return Icons.inbox;
    if (mailbox.isSent) return Icons.send;
    if (mailbox.isTrash) return Icons.delete;
    if (mailbox.isSpam) return Icons.report;
    if (mailbox.isDrafts) return Icons.drafts;
    if (mailbox.isArchive) return Icons.archive;
    return Icons.folder;
  }
}
```

#### 3.2 Modifier `inbox_screen.dart`

**Ajouter le Drawer** :
```dart
@override
Widget build(BuildContext context) {
  final currentMailbox = ref.watch(currentMailboxProvider);
  final emailsAsync = ref.watch(currentMailboxEmailsProvider); // Utiliser le nouveau provider

  return Scaffold(
    drawer: MailboxDrawer(), // NOUVEAU
    appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(currentMailbox == 'INBOX' ? 'Boîte de réception' : currentMailbox),
      // ... reste du code
    ),
    // ... reste du code
  );
}
```

---

### 🤖 Phase 4 : Assistant IA avec Navigation Dossiers (2h)

**Objectif** : L'IA peut changer de dossier et interagir avec tous les dossiers

#### 4.1 Modifier `jarvis_service.dart`

**Ajouter de nouveaux tools** :

```dart
{
  'name': 'list_mailboxes',
  'description': 'Liste tous les dossiers disponibles (Inbox, Sent, Trash, Spam, etc.).',
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
        'description': 'Le chemin du dossier (ex: "INBOX", "Sent", "Spam")',
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
        'description': 'Le dossier de destination (ex: "Trash", "Archive")',
      },
    },
    'required': ['email_id', 'target_folder'],
  },
},
```

**Implémenter les tools** :

```dart
Future<String> _listMailboxes() async {
  final mailboxes = await _emailService.getMailboxes();

  final mailboxList = mailboxes.map((m) => {
    'path': m.path,
    'name': m.name,
    'message_count': m.messagesExists,
    'unseen_count': m.messagesUnseen,
  }).toList();

  return jsonEncode({
    'count': mailboxes.length,
    'mailboxes': mailboxList,
  });
}

Future<String> _selectMailbox(Map<String, dynamic> input) async {
  final mailboxPath = input['mailbox_path'] as String;

  await _emailService.selectMailbox(mailboxPath);

  // Mettre à jour le provider Riverpod (nécessite une ref)
  // Note: Il faut passer ProviderContainer au service

  return 'Dossier "$mailboxPath" sélectionné avec succès.';
}

Future<String> _moveEmail(Map<String, dynamic> input) async {
  final emailId = (input['email_id'] as num).toInt();
  final targetFolder = input['target_folder'] as String;

  final email = await _isar.emailModels.get(emailId);

  if (email == null) {
    return 'Email avec l\'ID $emailId introuvable.';
  }

  await _emailService.moveEmail(email.uid, targetFolder);

  // Mettre à jour le champ mailboxPath dans Isar
  email.mailboxPath = targetFolder;
  await _isar.writeTxn(() async {
    await _isar.emailModels.put(email);
  });

  return 'Email déplacé vers "$targetFolder" avec succès.';
}
```

**Modifier le system prompt** :

```dart
String _getSystemPrompt() {
  return '''Tu es un assistant IA personnel pour gérer la messagerie La Poste.

Tu peux :
- Lire et résumer les emails de n'importe quel dossier
- Changer de dossier (Inbox, Sent, Trash, Spam, Archive, etc.)
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
```

---

### 🔧 Phase 5 : Ajustements Finaux (1h)

#### 5.1 Régénérer les fichiers Isar
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 5.2 Tester les scénarios
- Navigation entre dossiers depuis le Drawer
- Synchronisation des emails par dossier
- Commandes IA :
  - "Va voir dans le dossier Indésirables"
  - "Déplace cet email vers la Corbeille"
  - "Montre-moi mes emails envoyés"
  - "Nettoie le dossier Corbeille"

#### 5.3 Optimisations
- Ajouter un cache pour les mailboxes (refresh tous les 5 min)
- Ajouter un indicateur de chargement lors du changement de dossier
- Ajouter une gestion d'erreur robuste

---

## Résumé des Modifications

### Fichiers à Créer
1. `lib/models/mailbox_model.dart`
2. `lib/widgets/mailbox_drawer.dart`

### Fichiers à Modifier
1. `lib/theme/app_theme_2025.dart` - Refonte palette couleurs
2. `lib/services/email_service.dart` - Ajouter getMailboxes, selectMailbox, moveEmail
3. `lib/services/jarvis_service.dart` - Ajouter 3 nouveaux tools
4. `lib/models/email_model.dart` - Ajouter champ mailboxPath
5. `lib/providers/email_providers.dart` - Ajouter providers mailboxes
6. `lib/screens/home_screen.dart` - Inverser ordre onglets, changer labels
7. `lib/screens/inbox_screen.dart` - Ajouter Drawer, utiliser nouveau provider
8. `lib/screens/chat_screen.dart` - Changer design (blanc/jaune)

### Commandes à Exécuter
```bash
# Régénérer Isar après avoir modifié les models
dart run build_runner build --delete-conflicting-outputs

# Tester l'application
flutter run
```

---

## Bénéfices de cette Architecture

✅ **Séparation claire** : Email classique (onglet 1) vs Assistant IA (onglet 2)
✅ **Accès complet** : Tous les dossiers IMAP accessibles (Inbox, Sent, Trash, Spam, Archive, etc.)
✅ **IA intelligente** : Peut naviguer entre dossiers et effectuer des actions avancées
✅ **Design pro** : Blanc/Jaune La Poste, clean et minimaliste
✅ **Performance** : Cache local avec Isar, synchronisation incrémentale
✅ **UX fluide** : Drawer pour navigation rapide, BottomBar pour switch Email/Assistant

---

## Prochaines Étapes (Après Approbation)

1. Phase 1 : Refonte Design (commencer par app_theme_2025.dart)
2. Phase 2 : EmailService + Modèles
3. Phase 3 : Interface Drawer
4. Phase 4 : Assistant IA amélioré
5. Phase 5 : Tests et optimisations

**Estimation totale** : 10 heures de développement
