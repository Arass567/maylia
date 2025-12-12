import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/email_model.dart';
import '../providers/email_providers.dart';
import '../widgets/ai_writer_dialog.dart';
import '../widgets/move_email_sheet.dart';
import '../services/gatekeeper_service.dart';
import '../services/perplexity_service.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../theme/app_theme_2025.dart';

class EmailDetailScreen extends ConsumerStatefulWidget {
  final EmailModel email;

  const EmailDetailScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends ConsumerState<EmailDetailScreen> {
  final _replyController = TextEditingController();
  bool _showReplyField = false;
  bool _isSending = false;

  bool _isNewSender = false;
  bool _isTrusted = true; // Par défaut on suppose true pour ne pas effrayer, sauf si check dit le contraire

  EmailModel? _loadedEmail; // Email avec le corps complet chargé
  bool _isLoadingBody = false;

  @override
  void initState() {
    super.initState();

    // Initialiser avec les données en cache pour éviter le flicker
    if (widget.email.senderTrustStatus == 'blocked') {
      _isTrusted = false;
      _isNewSender = false;
    } else if (widget.email.senderTrustStatus == 'trusted') {
      _isTrusted = true;
      _isNewSender = false;
    } else if (widget.email.senderTrustStatus == 'unknown') {
      _isNewSender = true;
    }

    // Marquer comme lu au chargement
    if (!widget.email.isRead) {
      Future.microtask(() => _markAsRead());
    }
    _checkSenderStatus();

    // Charger le corps de l'email si nécessaire
    _loadEmailBodyIfNeeded();
  }

  Future<void> _loadEmailBodyIfNeeded() async {
    // Vérifier si le corps doit être chargé
    if (widget.email.body.contains('[Corps non téléchargé') ||
        widget.email.body.contains('[Email sans contenu')) {
      setState(() => _isLoadingBody = true);

      try {
        final loadedEmail = await ref.read(loadEmailBodyProvider(widget.email.id).future);
        if (mounted) {
          setState(() {
            _loadedEmail = loadedEmail;
            _isLoadingBody = false;
          });
        }
      } catch (e) {
        print('❌ Erreur chargement corps: $e');
        if (mounted) {
          setState(() => _isLoadingBody = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Impossible de charger le contenu: $e'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _checkSenderStatus() async {
    final gatekeeper = ref.read(gatekeeperServiceProvider);
    final isNew = await gatekeeper.isNewSender(widget.email.displayEmail);
    final status = await gatekeeper.getSenderStatus(widget.email.displayEmail);

    if (mounted) {
      setState(() {
        _isNewSender = isNew;
        if (status != null) {
          _isTrusted = status.isTrusted;
          _isNewSender = false; // Si on a un status, ce n'est plus "nouveau" au sens strict
        }
      });
    }
  }

  Future<void> _trustSender() async {
    HapticFeedback.mediumImpact();
    await ref.read(gatekeeperServiceProvider).trustSender(
      widget.email.displayEmail,
      widget.email.displayFrom,
    );
    if (mounted) {
      setState(() {
        _isNewSender = false;
        _isTrusted = true;
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Expéditeur ajouté aux favoris')),
      );
    }
  }

  Future<void> _blockSender() async {
    HapticFeedback.heavyImpact();
    await ref.read(gatekeeperServiceProvider).blockSender(
      widget.email.displayEmail,
      widget.email.displayFrom,
    );
    if (mounted) {
      setState(() {
        _isNewSender = false;
        _isTrusted = false;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 Expéditeur bloqué')),
      );
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    try {
      await ref.read(markAsReadProvider(widget.email.id).future);
    } catch (e) {
      print('⚠️ Erreur marquage lu: $e');
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Le message ne peut pas être vide')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final replyData = {
        'to': widget.email.displayEmail,
        'subject': 'Re: ${widget.email.subject}',
        'body': _replyController.text.trim(),
      };

      await ref.read(sendEmailProvider(replyData).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Réponse envoyée')),
        );

        setState(() {
          _showReplyField = false;
          _replyController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }



  Future<void> _checkReputation() async {
    HapticFeedback.lightImpact();
    setState(() => _isSending = true); // Utiliser le loader existant ou un autre
    try {
      final perplexity = ref.read(perplexityServiceProvider);
      final result = await perplexity.checkSenderReputation(widget.email.displayEmail);

      if (mounted) {
        HapticFeedback.mediumImpact();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.public, color: Colors.blue),
                SizedBox(width: 8),
                Text('Réputation Web'),
              ],
            ),
            content: Text(result),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _markAsUnread() async {
    try {
      await ref.read(markAsUnreadProvider(widget.email.id).future);

      if (mounted) {
        Navigator.pop(context); // Retour à la liste
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✉️ Email marqué comme non lu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMoveSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MoveEmailSheet(emailId: widget.email.id),
    ).then((_) {
      // Retour à la liste après déplacement
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _shareEmail() {
    // Utiliser l'email chargé si disponible
    final displayEmail = _loadedEmail ?? widget.email;

    final shareText = '''
De: ${displayEmail.displayFrom} (${displayEmail.displayEmail})
Date: ${DateFormat('dd/MM/yyyy HH:mm').format(displayEmail.date)}
Sujet: ${displayEmail.subject}

${displayEmail.body}
''';

    Share.share(
      shareText,
      subject: displayEmail.subject,
    );
  }

  Future<void> _deleteEmail() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet email ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(deleteEmailProvider(widget.email.id).future);

        if (mounted) {
          Navigator.pop(context); // Retour à la liste
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Email supprimé du serveur et de l\'app'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur suppression: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_unread':
                  _markAsUnread();
                  break;
                case 'move':
                  _showMoveSheet();
                  break;
                case 'share':
                  _shareEmail();
                  break;
                case 'delete':
                  _deleteEmail();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (widget.email.isRead)
                const PopupMenuItem(
                  value: 'mark_unread',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_unread_outlined),
                      SizedBox(width: 12),
                      Text('Marquer comme non lu'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move_outlined),
                    SizedBox(width: 12),
                    Text('Déplacer vers...'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 12),
                    Text('Partager'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gatekeeper Banner
                  if (_isNewSender || !_isTrusted) _buildGatekeeperBanner(),
                  const SizedBox(height: 16),
                  // En-tête
                  _buildHeader(),
                  const Divider(height: 32),
                  // Analyse IA
                  if (widget.email.isAiAnalyzed) _buildAiAnalysis(),
                  // Corps de l'email
                  _buildBody(),
                ],
              ),
            ),
          ),
          // Champ de réponse
          if (_showReplyField) _buildReplyField(),
        ],
      ),
      floatingActionButton: !_showReplyField
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() => _showReplyField = true);
              },
              icon: const Icon(Icons.reply),
              label: const Text('Répondre'),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final emailService = ref.read(emailServiceProvider);
    final isSenderMe = emailService.userEmail == widget.email.displayEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sujet
        Text(
          widget.email.subject,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Expéditeur
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getImportanceColor(),
              child: Text(
                widget.email.displayFrom.isNotEmpty
                    ? widget.email.displayFrom[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.email.displayFrom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.email.displayEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy à HH:mm', 'fr')
                        .format(widget.email.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (!isSenderMe)
              IconButton(
                icon: const Icon(CupertinoIcons.sparkles),
                tooltip: 'En savoir plus sur l\'expéditeur',
                onPressed: () => _showSenderContextSheet(context),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Analyse IA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Résumé
          if (widget.email.aiResume != null) ...[
            const Text(
              'Résumé :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email.aiResume!,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
          ],
          // Importance et catégorie
          Row(
            children: [
              if (widget.email.aiImportance != null) ...[
                _buildInfoChip(
                  'Importance: ${widget.email.aiImportance}',
                ),
                const SizedBox(width: 8),
              ],
              if (widget.email.aiCategory != null)
                _buildInfoChip(
                  widget.email.aiCategory!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme2025.sm, vertical: AppTheme2025.xxs),
      decoration: BoxDecoration(
        color: AppTheme2025.paleCream, // Pale cream background
        borderRadius: BorderRadius.circular(AppTheme2025.radiusXl), // Very rounded
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black, // Black text for contrast
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Utiliser l'email chargé si disponible, sinon l'email original
    final displayEmail = _loadedEmail ?? widget.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message :',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isLoadingBody
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Chargement du contenu...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SelectableText(
                  displayEmail.body.isNotEmpty
                      ? displayEmail.body
                      : '(Pas de contenu)',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
        ),
        if (displayEmail.hasAttachments)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Pièces jointes disponibles',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReplyField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.reply, size: 20),
              const SizedBox(width: 8),
              Text(
                'Répondre à ${widget.email.displayFrom}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showReplyField = false;
                    _replyController.clear();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _replyController,
            maxLines: 4,
            enabled: !_isSending,
            decoration: InputDecoration(
              hintText: 'Votre message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.orange),
                tooltip: 'Répondre avec l\'IA',
                onPressed: () async {
                  final result = await showDialog<Map<String, String?>>(
                    context: context,
                    builder: (context) => AiWriterDialog(
                      originalBody: widget.email.body,
                    ),
                  );
                  
                  if (result != null && result['body'] != null) {
                    setState(() {
                      _replyController.text = result['body']!;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _sendReply,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Envoi...' : 'Envoyer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getImportanceColor() {
    switch (widget.email.aiImportance?.toLowerCase()) {
      case 'haute':
        return Colors.red;
      case 'moyenne':
        return Colors.orange;
      case 'faible':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildGatekeeperBanner() {
    if (!_isTrusted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Expéditeur bloqué. Soyez prudent.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: _trustSender,
              child: const Text('Débloquer'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Nouvel expéditeur',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez jamais échangé avec ${widget.email.displayEmail}.',
            style: TextStyle(color: Colors.blue[900]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _checkReputation,
                  icon: const Icon(Icons.public, size: 16),
                  label: const Text('Vérifier (Web)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _blockSender,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Bloquer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _trustSender,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accepter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSenderContextSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme2025.radiusXl)),
      ),
      builder: (context) {
        return _SenderContextSheetContent(
          senderName: widget.email.displayFrom,
          senderEmail: widget.email.displayEmail,
          perplexityService: ref.read(perplexityServiceProvider),
        );
      },
    );
  }
}

class _SenderContextSheetContent extends StatefulWidget {
  final String senderName;
  final String senderEmail;
  final PerplexityService perplexityService;

  const _SenderContextSheetContent({
    required this.senderName,
    required this.senderEmail,
    required this.perplexityService,
  });

  @override
  State<_SenderContextSheetContent> createState() =>
      _SenderContextSheetContentState();
}

class _SenderContextSheetContentState
    extends State<_SenderContextSheetContent> {
  bool _isLoading = true;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContext();
  }

  Future<void> _fetchContext() async {
    try {
      final contextResult = await widget.perplexityService.enrichSenderContext(
        senderName: widget.senderName,
        senderEmail: widget.senderEmail,
      );
      if (mounted) {
        setState(() {
          _result = contextResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de récupérer le contexte : $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme2025.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.sparkles,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: AppTheme2025.sm),
                Text(
                  'Contexte de l\'expéditeur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: AppTheme2025.lg),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoading
                    ? const Center(
                        key: ValueKey('loading'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppTheme2025.md),
                            Text('Recherche d\'informations...'),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            key: const ValueKey('error'),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('result'),
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _result ?? 'Aucun résultat.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
