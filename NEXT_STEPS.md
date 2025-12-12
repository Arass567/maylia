# Prochaines Étapes - Smart Mail La Poste

## 📋 Fonctionnalités à implémenter

### 🔗 Gestion des Pièces Jointes
**Priorité: HAUTE**

#### Étapes d'implémentation:

1. **Modifier le modèle de données (EmailModel)**
   - Ajouter un champ `List<Attachment> attachments`
   - Créer une classe `Attachment` avec:
     - `String filename` - Nom du fichier
     - `int size` - Taille en octets
     - `String mimeType` - Type MIME (image/jpeg, application/pdf, etc.)
     - `String? localPath` - Chemin local si téléchargé
     - `bool isDownloaded` - Statut de téléchargement
   - Régénérer le schéma Isar avec `flutter pub run build_runner build --delete-conflicting-outputs`

2. **Récupérer les métadonnées des pièces jointes (email_service.dart)**
   - Utiliser `message.bodyStructure` pour extraire les pièces jointes
   - Parser les informations: nom, taille, type MIME
   - Stocker les métadonnées dans Isar lors de la synchro

3. **Créer l'UI d'affichage des pièces jointes (email_detail_screen.dart)**
   - Widget `AttachmentsList` pour afficher les pièces jointes
   - Afficher: nom, taille formatée (KB/MB), icône selon le type
   - Actions: télécharger, ouvrir, partager

4. **Implémenter le téléchargement**
   - Ajouter dépendance `path_provider` pour le stockage local
   - Créer un provider `downloadAttachmentProvider`
   - Télécharger via IMAP avec `message.fetchPart()`
   - Sauvegarder dans le stockage local de l'app
   - Mettre à jour le champ `localPath` dans Isar

5. **Ouvrir les pièces jointes**
   - Ajouter dépendance `open_file` ou `url_launcher`
   - Permettre d'ouvrir avec l'app par défaut du système
   - Supporter images, PDF, documents Office

#### Fichiers à modifier:
- `lib/models/email_model.dart` - Ajouter le modèle Attachment
- `lib/services/email_service.dart` - Extraire les métadonnées IMAP
- `lib/providers/email_providers.dart` - Provider de téléchargement
- `lib/screens/email_detail_screen.dart` - UI de liste des pièces jointes
- `lib/widgets/attachment_card.dart` - Widget pour afficher une pièce jointe

#### Estimation de temps: 4-6 heures de développement

---

## ✅ Améliorations récentes (12/12/2024)

### Interface Chat
- ✅ Fond d'écran géométrique personnalisé (motif orange/bleu)
- ✅ Avatar utilisateur personnalisé (perroquet avec lunettes)
- ✅ Correction des erreurs de widgets `Expanded` dans inbox_screen

### Affichage des Emails
- ✅ Support HTML - Les emails sont maintenant rendus avec leur formatage HTML d'origine
- ✅ Liens cliquables et mise en forme préservée
- ✅ Fallback sur texte brut si pas de HTML

### Analyse IA
- ✅ Augmentation de la limite de caractères: 1500 → 5000 caractères
- ✅ L'IA a maintenant accès à beaucoup plus de contenu pour des analyses précises
- ⚠️ **Note**: L'IA ne peut toujours pas accéder aux pièces jointes (sera implémenté avec la gestion complète des PJ)

---

## 📝 Notes de développement

### Commandes utiles

```bash
# Lancer l'app
flutter run

# Régénérer le schéma Isar après modification des modèles
flutter pub run build_runner build --delete-conflicting-outputs

# Créer un commit
git add .
git commit -m "Message de commit"

# Mettre à jour les dépendances
flutter pub get
```

### Architecture actuelle

- **State Management**: Riverpod
- **Base de données**: Isar (NoSQL embarquée)
- **Email**: enough_mail (IMAP/SMTP)
- **IA**: Anthropic Claude Sonnet 4.5
- **Recherche Web**: Perplexity API
- **Sécurité**: flutter_secure_storage pour les credentials

---

## 🎯 Roadmap

### Court terme (1-2 semaines)
- [ ] Gestion complète des pièces jointes
- [ ] Améliorer la recherche d'emails
- [ ] Ajouter des filtres avancés

### Moyen terme (1 mois)
- [ ] Mode hors ligne complet
- [ ] Notifications push pour nouveaux emails
- [ ] Synchronisation en arrière-plan

### Long terme (3+ mois)
- [ ] Support multi-comptes
- [ ] Widgets home screen
- [ ] Thèmes personnalisables
