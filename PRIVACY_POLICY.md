# Politique de Confidentialité de Maylia

**Dernière mise à jour : 27 Décembre 2025**

Cette politique de confidentialité explique comment l'application **Maylia** ("nous", "notre", "nos") recueille, utilise, divulgue et protège vos informations (y compris vos emails et données vocales) lorsque vous utilisez notre application mobile.

En utilisant Maylia, vous acceptez les pratiques décrites dans cette politique.

## 1. Informations que nous collectons

### A. Données de compte Email (IMAP/SMTP)
Pour fournir ses services, Maylia se connecte à vos fournisseurs de messagerie (ex: La Poste, Gmail).
- **Identifiants** : Nous stockons vos identifiants (email et mot de passe/token OAuth) de manière cryptée et sécurisée sur votre appareil, exclusivement via le stockage sécurisé du système (Android Keystore).
- **Contenu des emails** : L'application télécharge et analyse vos emails pour vous fournir des résumés intelligents, des tris automatiques et des fonctionnalités de réponse. Ces données sont stockées localement sur votre appareil.

### B. Données Vocales et Audio
Maylia propose un **assistant vocal intelligent**.
- **Utilisation du Microphone** : Lorsque vous activez le mode conversation (via le bouton micro ou briefing), nous accédons à votre microphone pour enregistrer vos commandes vocales.
- **Traitement** : Les données audio sont transmises à des services tiers (Speech-to-Text) uniquement le temps de la transcription. **Aucun enregistrement audio n'est conservé sur nos serveurs.**

### C. Informations sur l'appareil
Nous pouvons collecter des informations techniques sur votre appareil (modèle, version d'OS) pour le diagnostic d'erreurs et l'amélioration de l'application.

## 2. Comment nous utilisons vos informations

Nous utilisons vos données pour :
- **Gérer vos emails** : Lire, écrire, envoyer et organiser vos messages.
- **Assistant Maylia** :
    - Analyser le contenu des emails pour générer des résumés et des brouillons de réponse.
    - Interagir vocalement avec vous et exécuter vos commandes.
    - Créer un briefing quotidien personnalisé (basé sur votre calendrier et vos emails non lus).
- **Amélioration du service** : Détecter et corriger les bugs.

## 3. Partage de données avec des tiers

Nous ne vendons **jamais** vos données personnelles. Cependant, pour fournir nos services d'intelligence artificielle, certaines données sont transmises à des fournisseurs tiers de confiance :

- **OpenAI & Anthropic** : Le contenu textuel de vos emails (pour résumés/réponses) et vos commandes vocales peuvent être transmis à ces services pour traitement.
    - *Note* : Ces données sont utilisées uniquement pour générer des réponses en temps réel et ne sont pas utilisées par ces tiers pour entraîner leurs modèles publics (selon leurs politiques API entreprises).
- **Perplexity AI** : Utilisé pour enrichir les briefings d'actualités.
- **Google Firebase** : Pour les notifications push (aucune donnée sensible d'email n'est transmise via les notifications).

## 4. Sécurité des données

La sécurité de vos données est notre priorité :
- **Stockage local** : La majorité de vos données (base de données emails, mémoire de l'assistant) reste sur votre appareil.
- **Chiffrement** : Vos identifiants sont chiffrés. Les communications avec les serveurs (IMAP/SMTP/API IA) sont sécurisées via TLS/SSL.
- **Contrôle** : Vous pouvez à tout moment déconnecter votre compte ou supprimer l'application, ce qui effacera toutes les données locales.

## 5. Vos droits et contrôles

- **Permissions Android** : Vous pouvez révoquer l'accès au microphone ou aux notifications à tout moment dans les paramètres de votre téléphone.
- **Suppression** : Vous pouvez supprimer votre compte de l'application via les paramètres.

## 6. Utilisation du Microphone (Spécifique Google Play)

Conformément aux exigences de Google Play :
- L'accès au microphone est **optionnel** et n'est activé que lorsque vous initiez une interaction vocale avec Maylia.
- Aucune écoute passive n'est effectuée en arrière-plan.
- Un indicateur visuel (bouton micro animé) est toujours présent lorsque l'enregistrement est actif.

## 7. Contact

Pour toute question concernant cette politique de confidentialité, vous pouvez nous contacter :
- Email : support@maylia-app.com
- GitHub : https://github.com/Assani/smart_mail_laposte/issues

---
*Cette application est un projet indépendant et n'est pas affiliée officiellement au Groupe La Poste.*
