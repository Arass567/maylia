# Démarrage rapide - JARVIS Email Assistant

## En 5 minutes chrono !

### 1. Configurer vos identifiants (2 min)

Éditez `.env` :
```env
EMAIL_ADDRESS=votre.email@laposte.net
EMAIL_PASSWORD=votre_mot_de_passe
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx
```

**Obtenir une clé API Anthropic :**
1. Allez sur https://console.anthropic.com/
2. Créez un compte / Connectez-vous
3. Section "API Keys"
4. "Create Key"
5. Copiez dans `.env`

### 2. Installer (2 min)

**Windows :**
```bash
setup.bat
```

**Linux/Mac :**
```bash
chmod +x setup.sh
./setup.sh
```

**Ou manuellement :**
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Lancer (1 min)

```bash
flutter run
```

Ou appuyez sur **F5** dans VS Code

---

## Première utilisation

### Écran JARVIS (principal)

L'app démarre sur l'interface de chat avec JARVIS.

**Essayez :**
```
"Salut Jarvis"
"Synchronise mes emails"
"Montre-moi mes emails non lus"
```

### Navigation

**Barre du bas :**
- **JARVIS** 🧠 - Chat avec l'assistant IA
- **Inbox** 📬 - Vue traditionnelle des emails

---

## Exemples de commandes JARVIS

### Basiques
```
"Quels sont mes nouveaux emails ?"
"Combien d'emails non lus ?"
"Synchronise mes emails"
```

### Filtrage
```
"Montre-moi les emails importants"
"Affiche les emails de haute importance"
"Liste les 10 derniers emails"
```

### Recherche
```
"Recherche les emails de Jean"
"Trouve 'facture' dans mes emails"
"Cherche dans le sujet 'réunion'"
```

### Actions
```
"Lis l'email numéro 5"
"Réponds à l'email 3 en disant 'Merci, bien reçu'"
"Envoie un email à jean@example.com avec le sujet 'Test'"
"Supprime l'email numéro 7"
```

---

## Résolution de problèmes rapide

### "Connexion IMAP échouée"
- ✅ Vérifiez `.env` : email et mot de passe corrects
- ✅ IMAP activé sur votre compte La Poste

### "Erreur API Anthropic"
- ✅ Clé API valide dans `.env`
- ✅ Quota API non épuisé sur console.anthropic.com

### "Fichier .g.dart manquant"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### JARVIS ne répond pas
- ✅ Connexion Internet active
- ✅ Clé API configurée
- ✅ Consultez les logs dans la console

---

## Raccourcis clavier

- **Entrée** : Envoyer message à JARVIS
- **F5** : Lancer l'app (VS Code)
- **Ctrl+C** : Stopper l'app

---

## Prochaines étapes

📚 **Guides détaillés :**
- `JARVIS_GUIDE.md` - Guide complet de JARVIS
- `README.md` - Documentation technique
- `INSTRUCTIONS.md` - Instructions détaillées

🎨 **Personnalisation :**
- Modifier la personnalité de JARVIS : `lib/services/jarvis_service.dart:24`
- Changer les couleurs : `lib/main.dart:44`

🔧 **Configuration avancée :**
- Nombre d'emails à récupérer : `lib/providers/email_providers.dart:34`
- Modèle IA : `lib/services/jarvis_service.dart:9`

---

## Support

🐛 Problème ? Consultez :
1. Les logs dans la console
2. Le fichier `.env`
3. La documentation complète

---

**Vous êtes prêt ! Discutez avec JARVIS comme Tony Stark ! 🚀**
