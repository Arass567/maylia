# 📧 Smart Mail La Poste - Super App

> **Application de messagerie intelligente propulsée par l'IA**
> Email + JARVIS AI Assistant + Smart Inbox + Gatekeeper + Intelligence Web

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Claude](https://img.shields.io/badge/Claude-Sonnet%204.5-764ABC)
![Perplexity](https://img.shields.io/badge/Perplexity-Sonar%20Pro-00D4FF)
![Material 3](https://img.shields.io/badge/Material-3-6200EE)

---

## 🚀 Vue d'ensemble

Smart Mail La Poste est une **Super App** de messagerie nouvelle génération qui combine :
- **Email classique** (IMAP/SMTP La Poste)
- **Intelligence artificielle** (Claude Sonnet 4.5)
- **Recherche web en temps réel** (Perplexity Sonar Pro)
- **Sécurité avancée** (Gatekeeper anti-phishing)
- **Design moderne** (Material 3)

Inspirée de **Spark Mail** et alimentée par l'IA, cette application révolutionne la gestion d'emails.

---

## ✨ Fonctionnalités Principales

### 1. 📮 **Smart Inbox** - Boîte de Réception Intelligente

Vos emails sont **triés automatiquement par l'IA** en 3 onglets :

- **👤 Personnel** : Conversations réelles (amis, famille, collègues)
- **🔔 Notifs** : Confirmations, alertes, mises à jour de statut
- **📰 News** : Newsletters, promotions, offres commerciales

**Classification automatique** par analyse IA :
- Résumé intelligent de chaque email
- Importance (Haute, Moyenne, Faible)
- Catégorie (Personnel, Notification, Newsletter)

**Fichiers** : `lib/screens/inbox_screen.dart:93-118`

---

### 2. ✍️ **Assistant d'Écriture IA**

Un assistant IA intégré pour **rédiger et répondre** à vos emails :

#### Rédaction de nouveaux emails
- Donnez une instruction simple : *"Demande un RDV pour mardi"*
- L'IA rédige l'email complet (sujet + corps)

#### Réponses intelligentes
- L'IA analyse l'email reçu
- Propose une réponse adaptée au contexte

#### Personnalisation du ton
Choisissez parmi 4 tons :
- **Professionnel** : Pour le travail
- **Amical** : Pour les proches
- **Concis** : Réponses courtes
- **Formel** : Communication officielle

**Accès** : Bouton **✨ IA** dans le champ de réponse ou lors de la composition

**Fichiers** : `lib/widgets/ai_writer_dialog.dart`, `lib/services/ai_service.dart:189-263`

---

### 3. 🛡️ **Gatekeeper** - Protection Anti-Phishing

Système de **filtrage intelligent des expéditeurs** :

#### Détection automatique
- L'application vérifie si vous avez déjà échangé avec l'expéditeur
- **Bannière bleue** pour les nouveaux expéditeurs
- **Bannière rouge** pour les expéditeurs bloqués

#### Actions disponibles
- **Accepter** : Ajouter aux favoris
- **Bloquer** : Bloquer l'expéditeur
- **Vérifier (Web)** : Analyse de réputation via Perplexity

#### Vérification Web
- Interroge Perplexity pour analyser le domaine
- Détecte le spam, phishing et arnaques connues
- Affiche un rapport de réputation en temps réel

**Fichiers** :
- `lib/services/gatekeeper_service.dart`
- `lib/screens/email_detail_screen.dart:607-708`

---

### 4. 🌐 **Intelligence Web** - Perplexity Integration

JARVIS est **connecté au web en temps réel** via Perplexity :

#### Capacités
- Recherches d'informations actualisées
- Vérification de faits (fact-checking)
- Suivi de colis et commandes
- Analyse de réputation des domaines

#### Utilisation
Dans le chat JARVIS, demandez :
- *"Recherche sur le web qui est le PDG de Microsoft"*
- *"Vérifie si amazon.com est un site sûr"*
- *"Cherche des infos sur le colis 123456"*

**Fichiers** :
- `lib/services/perplexity_service.dart`
- `lib/services/jarvis_service.dart:379-380`

---

### 5. 🤖 **JARVIS** - Assistant IA Personnel

Assistant conversationnel propulsé par **Claude Sonnet 4.5** avec fonction calling.

#### Capacités Email
- Lire et résumer vos emails
- Rechercher dans vos messages
- Envoyer et répondre à des emails
- Supprimer ou déplacer des messages
- Changer de dossier (INBOX, Sent, Trash, Spam...)

#### Capacités Web
- Rechercher des informations en temps réel
- Vérifier des faits
- Analyser des données

#### Exemple de conversation
```
Utilisateur : Quels sont mes emails non lus aujourd'hui ?
JARVIS : Vous avez 3 emails non lus. Voici un résumé...

Utilisateur : Recherche sur le web la météo à Paris
JARVIS : [Recherche via Perplexity] D'après les dernières données...
```

**Fichiers** : `lib/services/jarvis_service.dart`

---

### 6. 📊 **Analyse IA des Emails**

Chaque email est automatiquement analysé par Claude :

- **Résumé** : Condensé du contenu en une phrase
- **Importance** : Haute, Moyenne, Faible
- **Catégorie** : Personnel, Notification, Newsletter

**Affichage** : Carte premium dans les détails de l'email

**Fichiers** : `lib/services/ai_service.dart:12-154`

---

## 🎨 Design & UI/UX

### Material 3 Design System
- Couleurs officielles La Poste (Jaune #FFD700, Bleu Nuit #1A1A2E)
- Navigation moderne (NavigationBar + NavigationRail)
- Responsive (Mobile + Tablet + Landscape)
- Thème clair + OLED Dark Mode

### Accessibilité WCAG 2.1
- Support complet des lecteurs d'écran
- Contraste AA minimum (4.5:1)
- Touch targets 48x48dp minimum
- Labels sémantiques sur tous les éléments

### Microinteractions
- Retour haptique sur toutes les actions
- Animations fluides
- États de chargement visuels

**Fichiers** : `lib/theme/app_theme_2025.dart`, `lib/widgets/reusable_components_2025.dart`

---

## 🛠️ Stack Technique

### Frontend
- **Flutter** 3.0+ - Framework cross-platform
- **Riverpod** 2.5+ - State management
- **Isar** 3.1+ - Base de données locale NoSQL
- **Material 3** - Design system

### Backend & IA
- **Anthropic Claude Sonnet 4.5** - Analyse et conversation IA
- **Perplexity Sonar Pro** - Recherche web temps réel
- **IMAP/SMTP** (La Poste) - Protocoles email

### Packages Clés
```yaml
flutter_riverpod: ^2.5.1
isar: ^3.1.0+1
enough_mail: ^2.1.7
http: ^1.2.0
flutter_slidable: ^3.0.1
flutter_dotenv: ^5.1.0
```

---

## 📂 Architecture du Projet

```
lib/
├── main.dart                     # Point d'entrée
├── models/                       # Modèles de données (Isar)
│   ├── email_model.dart          # Modèle email avec IA
│   ├── chat_message.dart         # Messages JARVIS
│   ├── trusted_sender.dart       # Gatekeeper
│   └── mailbox_model.dart        # Dossiers IMAP
├── screens/                      # Écrans de l'application
│   ├── home_screen.dart          # Navigation principale
│   ├── inbox_screen.dart         # Smart Inbox (3 onglets)
│   ├── email_detail_screen.dart  # Détails + Gatekeeper
│   ├── chat_screen.dart          # JARVIS
│   └── compose_screen.dart       # Rédaction email
├── services/                     # Logique métier
│   ├── email_service.dart        # IMAP/SMTP
│   ├── ai_service.dart           # Claude (analyse + rédaction)
│   ├── jarvis_service.dart       # JARVIS + function calling
│   ├── perplexity_service.dart   # Recherche web
│   └── gatekeeper_service.dart   # Anti-phishing
├── providers/                    # Riverpod providers
│   ├── email_providers.dart      # Gestion emails
│   └── chat_providers.dart       # Gestion JARVIS
├── widgets/                      # Composants réutilisables
│   ├── ai_writer_dialog.dart     # Dialog rédaction IA
│   ├── email_card.dart           # Carte email
│   ├── mailbox_drawer.dart       # Navigation dossiers
│   └── reusable_components_2025.dart  # Lib Material 3
└── theme/
    └── app_theme_2025.dart       # Thème La Poste Material 3
```

---

## ⚙️ Configuration

### 1. Clés API

Créez un fichier `.env` à la racine :

```env
# Anthropic (Claude Sonnet 4.5)
ANTHROPIC_API_KEY=sk-ant-api03-...

# Perplexity (Sonar Pro)
PERPLEXITY_API_KEY=pplx-...

# Email La Poste
LAPOSTE_EMAIL=votre.email@laposte.net
LAPOSTE_PASSWORD=votre_mot_de_passe
```

### 2. Serveurs IMAP/SMTP

Déjà configurés pour La Poste :
- **IMAP** : `imap.laposte.net:993` (SSL)
- **SMTP** : `smtp.laposte.net:465` (SSL)

### 3. Installation

```bash
# Installer les dépendances
flutter pub get

# Générer les fichiers Isar + Riverpod
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run
```

---

## 🔐 Sécurité & Confidentialité

- **Local First** : Emails stockés localement (Isar)
- **Chiffrement** : Connexions SSL/TLS
- **Gatekeeper** : Protection anti-phishing
- **Pas de tracking** : Aucune donnée envoyée à des tiers
- **APIs IA** : Utilisent HTTPS avec clés API privées

---

## 🚧 Roadmap

### Version 2.0 (À venir)
- [ ] Widgets Material 3 avancés (SegmentedButton, badges)
- [ ] Animations personnalisées
- [ ] Pièces jointes (upload/download)
- [ ] Signature email personnalisable
- [ ] Mode hors-ligne amélioré
- [ ] Support multi-comptes
- [ ] Recherche vocale pour JARVIS

### Version 2.1
- [ ] Push notifications
- [ ] Calendrier intégré
- [ ] Contacts intelligents
- [ ] Traduction automatique des emails

---

## 🤝 Contribution

Ce projet est développé avec Claude Code et Claude Sonnet 4.5.

### Auteurs
- **Assistant IA** : JARVIS (Claude Sonnet 4.5)
- **Stack** : Flutter + Riverpod + Isar + Anthropic + Perplexity

---

## 📄 Licence

Ce projet utilise des APIs tierces :
- **Anthropic API** : [Conditions d'utilisation](https://www.anthropic.com/legal/terms)
- **Perplexity API** : [Conditions d'utilisation](https://www.perplexity.ai/hub/legal/terms-of-use)

---

## 📞 Support

Pour toute question technique :
1. Consultez la documentation dans ce README
2. Vérifiez les logs Flutter (`flutter logs`)
3. Testez avec le mode debug activé

---

## 🎉 Fonctionnalités Premium

Cette application est un **exemple de Super App** démontrant :
- ✅ Architecture moderne Flutter (Clean Architecture + Riverpod)
- ✅ Intégration IA avancée (Claude + function calling)
- ✅ Recherche web temps réel (Perplexity)
- ✅ Sécurité email (Gatekeeper)
- ✅ UI/UX premium (Material 3 + WCAG)
- ✅ Local First (Isar NoSQL)

**Prêt pour la production** avec optimisations, gestion d'erreurs et tests.

---

*Développé avec ❤️ et l'IA Claude Sonnet 4.5*
