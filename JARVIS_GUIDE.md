# Guide d'utilisation de JARVIS

## Introduction

JARVIS (Just A Rather Very Intelligent System) est votre assistant IA personnel pour gérer votre boîte email La Poste. Inspiré du célèbre assistant d'Iron Man, JARVIS utilise Claude AI (Anthropic) pour comprendre et exécuter vos demandes en langage naturel.

## Interface

L'application dispose de 2 écrans principaux :

1. **JARVIS (Chat)** - Interface conversationnelle avec l'assistant IA
2. **Inbox** - Vue traditionnelle de la boîte de réception

Naviguez entre les écrans via la barre de navigation en bas.

## Capacités de JARVIS

### 1. Lire les emails

**Exemples de commandes :**
- "Quels sont mes nouveaux emails ?"
- "Montre-moi les emails non lus"
- "Affiche les emails importants"
- "Liste les emails de haute importance"
- "Quels emails ai-je reçus aujourd'hui ?"

**Ce que JARVIS peut filtrer :**
- Tous les emails
- Emails non lus uniquement
- Par importance (haute, moyenne, faible)
- Limiter le nombre de résultats

### 2. Rechercher des emails

**Exemples de commandes :**
- "Recherche les emails de Jean"
- "Trouve les emails avec le mot 'facture'"
- "Cherche dans le sujet 'réunion'"
- "Emails contenant 'urgent'"

**Champs de recherche :**
- Expéditeur (from)
- Sujet (subject)
- Corps du message (body)
- Tous les champs (all)

### 3. Obtenir les détails d'un email

**Exemples de commandes :**
- "Montre-moi les détails de l'email numéro 5"
- "Lis l'email de Marie en entier"
- "Affiche le contenu complet du dernier email"

JARVIS vous donnera :
- Expéditeur complet
- Destinataire
- Sujet
- Corps du message
- Date
- Importance IA
- Catégorie
- Résumé IA

### 4. Envoyer un email

**Exemples de commandes :**
- "Envoie un email à jean@example.com avec le sujet 'Réunion' et dis-lui 'On se voit demain à 10h'"
- "Écris un email à marie@laposte.net pour la remercier"

**Informations requises :**
- Adresse du destinataire
- Sujet de l'email
- Corps du message

### 5. Répondre à un email

**Exemples de commandes :**
- "Réponds à l'email numéro 3 en disant 'Bien reçu, merci'"
- "Réponds à Marie que je serai disponible demain"

**Informations requises :**
- ID de l'email (obtenu en listant les emails)
- Message de réponse

### 6. Supprimer un email

**Exemples de commandes :**
- "Supprime l'email numéro 7"
- "Efface le dernier email de la liste"

**Attention :** La suppression est définitive !

### 7. Compter les non lus

**Exemples de commandes :**
- "Combien d'emails non lus ?"
- "Nombre de nouveaux messages"

### 8. Synchroniser les emails

**Exemples de commandes :**
- "Synchronise mes emails"
- "Récupère les nouveaux messages"
- "Actualise la boîte de réception"

## Style de conversation avec JARVIS

JARVIS a une personnalité inspirée d'Iron Man :

- **Professionnel** : Il est efficace et précis
- **Courtois** : Il vous appelle "Monsieur" ou "Madame"
- **Légèrement sarcastique** : Avec une touche d'humour britannique
- **Concis** : Il va droit au but

**Exemples de réponses typiques :**
- "À votre service, Monsieur. J'ai trouvé 5 emails non lus."
- "Certainement. Email envoyé avec succès."
- "Bien reçu. L'email a été supprimé définitivement."

## Exemples de conversations complètes

### Scénario 1 : Vérifier et répondre à un email

```
Vous : "Jarvis, quels sont mes emails non lus ?"

JARVIS : "À votre service. Vous avez 3 emails non lus :
1. De Marie Dupont - Sujet : Réunion projet
2. De Jean Martin - Sujet : Question urgente
3. De Amazon - Sujet : Votre commande"

Vous : "Montre-moi les détails de l'email de Jean"

JARVIS : "Voici l'email de Jean Martin :
[Détails complets de l'email]"

Vous : "Réponds-lui que je le rappelle dans 1h"

JARVIS : "Réponse envoyée avec succès à Jean Martin."
```

### Scénario 2 : Gérer les emails importants

```
Vous : "Affiche-moi les emails de haute importance"

JARVIS : "Certainement. Voici vos emails prioritaires :
[Liste des emails importants]"

Vous : "Synchronise mes emails"

JARVIS : "Synchronisation terminée. 2 nouveaux emails récupérés."

Vous : "Montre-moi les nouveaux"

JARVIS : "Voici les derniers emails :
[Liste mise à jour]"
```

### Scénario 3 : Recherche et suppression

```
Vous : "Recherche les emails contenant 'newsletter'"

JARVIS : "J'ai trouvé 8 emails correspondants :
[Liste des emails]"

Vous : "Supprime l'email numéro 12"

JARVIS : "Bien reçu. Email supprimé définitivement."
```

## Conseils d'utilisation

### Soyez naturel
Parlez à JARVIS comme à un assistant humain. Il comprend le langage naturel.

**Bon :** "Jarvis, peux-tu me montrer mes emails importants ?"
**Aussi bon :** "Emails importants s'il te plaît"

### Utilisez les ID d'emails
Quand JARVIS liste des emails, notez leur numéro (ID) pour y faire référence.

**Exemple :**
```
JARVIS : "Vous avez 3 emails :
1. De Marie...
2. De Jean...
3. De Amazon..."

Vous : "Lis l'email numéro 2"
```

### Synchronisez régulièrement
Pour avoir les emails les plus récents, synchronisez avant de lire.

**Routine recommandée :**
1. "Synchronise mes emails"
2. "Quels sont les nouveaux ?"
3. [Actions sur les emails]

### Combinez les filtres
Soyez précis pour obtenir exactement ce que vous voulez.

**Exemples :**
- "Montre-moi les 5 derniers emails non lus"
- "Recherche 'facture' dans les emails de haute importance"

## Design et animations

### Couleurs
- **Bleu cyan (#00D9FF)** : Accent principal (style Arc Reactor)
- **Bleu foncé (#0A0E27)** : Arrière-plan
- **Gradient bleu** : Bulles de messages

### Animations
- **Avatar pulsant** : L'avatar de JARVIS pulse en permanence
- **Typing indicator** : 3 points animés quand JARVIS réfléchit
- **Ombres néon** : Effets lumineux sur les bulles

### Bulles de messages
- **Vos messages** : À droite, gradient bleu, avec votre avatar
- **Messages JARVIS** : À gauche, fond sombre avec bordure cyan, avatar JARVIS

## Fonctionnement technique

### Function Calling
JARVIS utilise la technologie "function calling" de Claude AI :
1. Vous envoyez une demande
2. Claude analyse et décide quelle fonction appeler
3. JARVIS exécute la fonction (lire emails, envoyer, etc.)
4. Claude reçoit le résultat et vous répond en langage naturel

### Historique de conversation
- JARVIS garde en mémoire toute votre conversation
- Vous pouvez faire référence à des emails précédemment mentionnés
- Le contexte est conservé entre les messages

### Réinitialisation
Cliquez sur l'icône refresh (↻) en haut à droite pour :
- Effacer toute la conversation
- Réinitialiser l'historique
- Recommencer à zéro

## Limitations

1. **Rate limiting API** : Trop de demandes rapides peuvent être bloquées
2. **Pièces jointes** : Pas encore supportées
3. **HTML riche** : Les emails HTML sont convertis en texte
4. **Recherche** : Limitée à 10 résultats max

## Dépannage

### JARVIS ne répond pas
- Vérifiez votre clé API Anthropic dans `.env`
- Vérifiez votre connexion Internet
- Consultez les logs dans la console

### Emails introuvables
- Synchronisez d'abord : "Synchronise mes emails"
- Vérifiez que vous êtes connecté à La Poste
- L'email peut avoir été supprimé

### Erreur d'envoi
- Vérifiez l'adresse du destinataire
- Vérifiez vos identifiants SMTP dans `.env`
- Assurez-vous que le sujet et le corps ne sont pas vides

## Sécurité et confidentialité

- Tous les emails sont stockés localement (Isar)
- Les conversations avec JARVIS sont aussi locales
- Seules vos questions sont envoyées à l'API Claude
- Aucune donnée n'est partagée avec des tiers

## Astuces avancées

### Commandes rapides

**Routine du matin :**
```
"Jarvis, synchronise et montre-moi mes emails importants non lus"
```

**Nettoyage rapide :**
```
"Recherche 'newsletter' puis supprime tous ces emails"
(Note : Vous devrez confirmer chaque suppression)
```

**Recherche multi-critères :**
```
"Trouve les emails de jean@example.com contenant 'projet' dans le sujet"
```

### Personnalité de JARVIS

Vous pouvez modifier la personnalité de JARVIS dans `lib/services/jarvis_service.dart:24-38`

Changez le prompt système pour :
- Un ton plus formel
- Plus d'humour
- Un style différent

## Raccourcis clavier

- **Entrée** : Envoyer le message
- **Shift + Entrée** : Nouvelle ligne (dans les futures versions)

## Support

Pour toute question :
1. Consultez la documentation technique dans `README.md`
2. Vérifiez les logs de la console
3. Vérifiez votre configuration `.env`

---

**Profitez de JARVIS et gérez vos emails comme Tony Stark !** 🚀
