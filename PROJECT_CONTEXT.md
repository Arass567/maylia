# Smart Mail La Poste - Contexte Projet

## Vue d'ensemble
Application mobile Flutter de gestion d'emails avec intelligence artificielle intégrée. Client email personnel avec analyse IA (Claude Sonnet 4.5), recherche web (Perplexity), et système de gestion de confiance des expéditeurs (Gatekeeper).

**Utilisateur:** Particulier gérant ses emails La Poste
**Objectif:** Client email moderne avec IA pour trier, analyser et répondre aux emails intelligemment

## Stack Technique

### Frontend
- **Flutter** (Dart) - Framework mobile multiplateforme
- **Riverpod** - State management (Provider 2.0)
- **Material Design** - UI avec thème personnalisé (AppTheme2025)

### Stockage Local
- **Isar Database** - Base NoSQL embarquée (EmailModel, MailboxModel, TrustedSenderModel)
- **flutter_secure_storage** - Stockage sécurisé des credentials

### Communication Email
- **enough_mail** - Client IMAP/SMTP pour recevoir/envoyer emails
- **Serveurs:** imap.laposte.net:993, smtp.laposte.net:465

### Services IA
- **Anthropic Claude API** (Claude Sonnet 4.5) - Analyse emails, résumés, rédaction
- **Perplexity API** - Recherche web, vérification réputation expéditeurs

### Autres
- **share_plus** - Partage d'emails
- **intl** - Internationalisation (français)

## Architecture Fichiers

```
lib/
├── main.dart                          # Point d'entrée
├── models/
│   ├── email_model.dart              # Modèle email (Isar)
│   ├── mailbox_model.dart            # Modèle dossier (Isar)
│   └── trusted_sender_model.dart     # Modèle expéditeurs (Isar)
├── services/
│   ├── email_service.dart            # Service IMAP/SMTP
│   ├── ai_service.dart               # Service Claude (analyse emails)
│   ├── perplexity_service.dart       # Service recherche web
│   ├── gatekeeper_service.dart       # Gestion confiance expéditeurs
│   └── secure_storage_service.dart   # Credentials sécurisés
├── providers/
│   └── email_providers.dart          # Providers Riverpod
├── screens/
│   ├── inbox_screen.dart             # Écran principal (liste emails)
│   ├── email_detail_screen.dart      # Détail d'un email
│   ├── chat_screen.dart              # Chat avec assistant IA
│   └── compose_screen.dart           # Composition email
├── widgets/
│   ├── ai_writer_dialog.dart         # Dialog rédaction IA
│   └── move_email_sheet.dart         # Dialog déplacement email
└── theme/
    └── app_theme_2025.dart           # Thème app (couleurs, style)
```

## Modèles de Données (Isar)

### EmailModel
```dart
- id: Id (auto-increment)
- uid: int (UID IMAP serveur)
- mailboxPath: String (INBOX, Sent, etc.)
- from: String (expéditeur brut)
- to: String
- subject: String
- body: String (texte brut)
- bodyHtml: String (HTML nettoyé)
- date: DateTime
- isRead: bool
- hasAttachments: bool
- aiResume: String? (résumé IA)
- aiImportance: String? (haute/moyenne/faible)
- aiCategory: String? (catégorie)
- isAiAnalyzed: bool
- senderTrustStatus: String? (trusted/blocked/unknown)
- createdAt: DateTime
- updatedAt: DateTime?
```

### MailboxModel
```dart
- id: Id
- name: String
- path: String
- flags: List<String>
```

### TrustedSenderModel
```dart
- id: Id
- email: String (index unique)
- name: String
- isTrusted: bool
- isBlocked: bool
- notes: String?
- createdAt: DateTime
```

## Fonctionnalités Actuelles

### ✅ Implémenté

1. **Gestion Emails**
   - Synchronisation IMAP (200 derniers emails)
   - Lecture/marquage lu/non lu
   - Suppression (serveur + local)
   - Déplacement entre dossiers
   - Composition et envoi (SMTP)
   - Réponse aux emails
   - Partage d'emails

2. **Analyse IA (Claude)**
   - Résumé automatique des emails
   - Catégorisation (personnel, travail, etc.)
   - Évaluation importance (haute/moyenne/faible)
   - Aide à la rédaction de réponses
   - Chat avec assistant (contexte: emails)

3. **Gatekeeper (Confiance Expéditeurs)**
   - Détection nouveaux expéditeurs
   - Système trust/block
   - Vérification réputation web (Perplexity)
   - Enrichissement contexte expéditeur

4. **Interface**
   - Thème moderne (jaune, bleu, crème)
   - Liste emails avec catégories
   - Détail email avec analyse IA
   - Chat assistant avec fond personnalisé
   - Avatar utilisateur personnalisé (perroquet avec lunettes)

5. **Stockage Sécurisé**
   - Credentials email chiffrés (flutter_secure_storage)
   - Clés API chiffrées (Anthropic, Perplexity)
   - Migration automatique depuis .env

### 🚧 En Cours / À Faire

1. **Pièces Jointes** (NEXT_STEPS.md)
   - Affichage liste attachments
   - Téléchargement
   - Ouverture avec apps système
   - Estimation: 4-6h

2. **Améliorations Futures**
   - Mode hors ligne complet
   - Push notifications
   - Synchronisation background
   - Multi-comptes
   - Widgets home screen
   - Thèmes personnalisables

## Services Principaux

### EmailService
- Connexion IMAP/SMTP
- Fetch emails (avec limite)
- Parsing MIME
- Envoi emails
- Gestion dossiers
- Synchronisation

### AiService (Claude)
- Analyse email: `analyzeEmail(subject, body)`
- Génération réponse: `generateEmailReply(originalEmail, userInstructions)`
- Chat: `chat(message, conversationHistory, emailContext)`
- Limite: 5000 caractères par email

### PerplexityService
- Vérification réputation: `checkSenderReputation(email)`
- Enrichissement contexte: `enrichSenderContext(name, email)`

### GatekeeperService
- Check nouveau: `isNewSender(email)`
- Get status: `getSenderStatus(email)`
- Trust/block: `trustSender(email, name)` / `blockSender(email, name)`

## Dernières Modifications (16 déc 2024)

### Commit a95c4b9: Amélioration affichage emails
**Problème:** Code HTML brut affiché dans les emails (balises visibles)

**Solution:**
- Fonction `_stripHtmlTags()` pour nettoyer HTML
- Enlève `<style>`, `<script>`, toutes balises HTML
- Décode entités HTML (`&nbsp;`, `&amp;`, etc.)
- Remplacement widget Html par SelectableText
- Fichier: `lib/screens/email_detail_screen.dart:632-652`

**Avant:**
```dart
Html(data: displayEmail.bodyHtml, ...)  // Problèmes de rendu
```

**Après:**
```dart
String _stripHtmlTags(String htmlText) { ... }
SelectableText(contentToDisplay, ...)  // Texte propre
```

### Commit précédent: Personnalisation chat
- Fond chat: `assets/images/chat_background.jpg` (motif géométrique)
- Avatar user: `assets/images/user_avatar.jpg` (perroquet lunettes)

## Configuration Requise

### Environnement (.env ou secure_storage)
```
EMAIL_ADDRESS=xxx@laposte.net
EMAIL_PASSWORD=xxx
IMAP_HOST=imap.laposte.net
IMAP_PORT=993
SMTP_HOST=smtp.laposte.net
SMTP_PORT=465
ANTHROPIC_API_KEY=sk-ant-xxx
PERPLEXITY_API_KEY=pplx-xxx
```

### Dépendances Principales (pubspec.yaml)
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  enough_mail: ^2.1.10
  http: ^1.2.2
  flutter_secure_storage: ^9.2.2
  share_plus: ^10.1.2
  intl: ^0.19.0
```

## Patterns de Code

### Providers (Riverpod)
```dart
final emailServiceProvider = Provider((ref) => EmailService(ref));
final emailsProvider = StreamProvider<List<EmailModel>>((ref) { ... });
final loadEmailBodyProvider = FutureProvider.family<EmailModel, int>((ref, id) { ... });
```

### Isar Queries
```dart
final emails = await isar.emailModels
  .filter()
  .mailboxPathEqualTo('INBOX')
  .sortByDateDesc()
  .limit(200)
  .findAll();
```

### Service Pattern
```dart
class XxxService {
  final Ref ref;
  XxxService(this.ref);

  Future<Result> doSomething() async {
    // Logic
  }
}
```

## Points d'Attention

### Sécurité
- Credentials TOUJOURS dans flutter_secure_storage
- JAMAIS commit .env avec vraies valeurs
- Validation inputs utilisateur

### Performance
- Limite fetch emails (200 max)
- Lazy loading corps emails
- Cache Isar pour données locales
- Limit caractères pour IA (5000)

### UX
- Loading states systématiques
- Error handling avec snackbars
- Haptic feedback pour actions importantes
- Animations smooth (AnimatedSwitcher)

## Workflow Git

### Structure Commits
```
<type>: <description courte>

<description détaillée>
<contexte et raisons>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:** feat, fix, refactor, docs, style, test

### Branches
- `master` - Branche principale (développement)

## Notes Importantes

1. **HTML dans Emails:**
   - Utiliser `_stripHtmlTags()` pour affichage
   - Ne PAS utiliser flutter_html (problèmes rendu)

2. **IA Claude:**
   - Modèle: claude-sonnet-4-5-20250929
   - Coût tokens: surveiller usage
   - Alternative possible: Gemini (moins cher)

3. **IMAP La Poste:**
   - Parfois emails sans date valide
   - UIDs peuvent avoir gaps
   - Warnings "invalid mail address" normaux

4. **Isar:**
   - Auto-increment IDs
   - Indexes sur: uid, mailboxPath, isRead, isAiAnalyzed
   - Inspector web: inspect.isar.dev

## Prochaine Session

**Focus potentiel:**
1. Implémenter pièces jointes (NEXT_STEPS.md)
2. Remplacer Claude par Gemini (économie tokens)
3. Améliorer sync emails (background)
4. Push notifications

---

**Dernière mise à jour:** 16 décembre 2024
**Version Flutter:** Stable
**Testé sur:** Pixel 8 (Android)
