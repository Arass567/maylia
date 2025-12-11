# Instructions de démarrage rapide

## Étape 1 : Configuration de l'environnement

### 1.1 Configurer vos identifiants

Éditez le fichier `.env` et remplacez les valeurs suivantes :

```env
EMAIL_ADDRESS=votre.email@laposte.net
EMAIL_PASSWORD=votre_mot_de_passe_laposte
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
```

### 1.2 Obtenir une clé API Anthropic

1. Allez sur https://console.anthropic.com/
2. Créez un compte ou connectez-vous
3. Allez dans "API Keys"
4. Créez une nouvelle clé API
5. Copiez-la dans votre fichier `.env`

## Étape 2 : Installation

### Option A : Utiliser le script automatique (Windows)

Double-cliquez sur `setup.bat`

### Option B : Manuelle

```bash
cd C:\Users\arass\smart_mail_laposte

# Installer les dépendances
flutter pub get

# Générer le code
flutter pub run build_runner build --delete-conflicting-outputs
```

## Étape 3 : Lancer l'application

```bash
flutter run
```

Ou depuis votre IDE :
- Visual Studio Code : F5
- Android Studio : Run

## Fonctionnalités de l'application

### Écran Inbox

1. **Synchronisation**
   - Cliquez sur l'icône refresh (↻) en haut à droite
   - Ou tirez vers le bas (pull to refresh)

2. **Filtrage par importance**
   - Cliquez sur l'icône filtre (⋮)
   - Choisissez : Tous / Haute / Moyenne / Faible

3. **Supprimer un email**
   - Glissez la carte vers la gauche
   - Appuyez sur "Supprimer"

4. **Ouvrir un email**
   - Appuyez sur la carte

### Écran Détail

1. **Lecture automatique**
   - L'email est marqué comme lu automatiquement

2. **Répondre**
   - Cliquez sur le bouton flottant "Répondre"
   - Écrivez votre message
   - Cliquez sur "Envoyer"

3. **Supprimer**
   - Cliquez sur l'icône poubelle en haut à droite

## Architecture de l'application

### Services

- **EmailService** (`lib/services/email_service.dart`)
  - `fetchNewEmails()` : Récupère les nouveaux emails
  - `deleteEmail(uid)` : Supprime un email
  - `sendEmail()` : Envoie une réponse
  - `markAsRead(uid)` : Marque comme lu

- **AiService** (`lib/services/ai_service.dart`)
  - `analyzeEmail()` : Analyse un email avec Claude
  - Retourne : résumé, importance, catégorie

### Stockage

- **Isar** : Base de données locale ultra-rapide
- **Cache automatique** : Les emails sont stockés localement
- **Synchronisation** : Seuls les nouveaux emails sont téléchargés

### State Management

- **Riverpod** : Gestion d'état réactive
- **Providers disponibles** :
  - `emailsProvider` : Liste des emails (stream)
  - `syncEmailsProvider` : Synchronisation
  - `deleteEmailProvider` : Suppression
  - `sendEmailProvider` : Envoi
  - `unreadCountProvider` : Nombre de non lus

## Personnalisation

### Changer le nombre d'emails récupérés

Dans `lib/providers/email_providers.dart:34`

```dart
final newEmails = await emailService.fetchAllEmails(limit: 50); // Changez 30 à 50
```

### Changer le modèle Claude

Dans `lib/services/ai_service.dart:7`

```dart
final String _model = 'claude-3-5-sonnet-20241022'; // Pour plus de précision
```

### Modifier les couleurs

Dans `lib/main.dart:38`

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF0000FF), // Changez la couleur
  brightness: Brightness.light,
),
```

## Debugging

### Logs

Les services affichent des logs dans la console :
- ✅ Succès
- ❌ Erreurs
- 📬 Emails récupérés
- 🤖 Analyse IA
- 🗑️ Suppression

### Problèmes courants

**"Connexion IMAP échouée"**
- Vérifiez vos identifiants dans `.env`
- Assurez-vous que l'IMAP est activé sur votre compte La Poste

**"Erreur API Anthropic"**
- Vérifiez votre clé API
- Vérifiez votre quota sur console.anthropic.com

**"Fichier .g.dart introuvable"**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Performance

- **Premier lancement** : Analyse IA de tous les emails (peut prendre du temps)
- **Lancements suivants** : Seuls les nouveaux emails sont analysés
- **Cache Isar** : Accès ultra-rapide aux emails déjà chargés

## Sécurité

- Ne commitez JAMAIS le fichier `.env`
- Toutes les connexions sont SSL/TLS
- Les mots de passe ne sont jamais stockés en clair
- L'API Key Anthropic est protégée

## Support

Pour toute question ou problème :
1. Consultez le README.md
2. Vérifiez les logs dans la console
3. Vérifiez que toutes les dépendances sont installées

Bon développement !
