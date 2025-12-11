import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/email_model.dart';
import '../providers/email_providers.dart';
import 'email_detail_screen.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _filterImportance = 'all';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Synchroniser au démarrage
    Future.microtask(() => _syncEmails());
  }

  Future<void> _syncEmails() async {
    setState(() => _isRefreshing = true);

    try {
      // Invalider le provider pour forcer une nouvelle synchronisation
      ref.invalidate(syncEmailsProvider);

      // Attendre la synchronisation
      await ref.read(syncEmailsProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Emails synchronisés'),
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
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailsAsync = ref.watch(emailsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Smart Mail'),
            unreadCount.when(
              data: (count) => Text(
                '$count non lu(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          // Filtre par importance
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterImportance = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('🌐 Tous')),
              const PopupMenuItem(value: 'haute', child: Text('🔴 Haute importance')),
              const PopupMenuItem(value: 'moyenne', child: Text('🟠 Moyenne importance')),
              const PopupMenuItem(value: 'faible', child: Text('🟢 Faible importance')),
            ],
          ),
          // Refresh
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _syncEmails,
          ),
        ],
      ),
      body: emailsAsync.when(
        data: (emails) {
          // Filtrer par importance
          final filteredEmails = _filterImportance == 'all'
              ? emails
              : emails.where((e) => e.aiImportance == _filterImportance).toList();

          if (filteredEmails.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun email',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _syncEmails,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Synchroniser'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _syncEmails,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredEmails.length,
              itemBuilder: (context, index) {
                final email = filteredEmails[index];
                return _EmailCard(
                  email: email,
                  onTap: () => _openEmailDetail(email),
                  onDelete: () => _deleteEmail(email),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _syncEmails,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEmailDetail(EmailModel email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(email: email),
      ),
    );
  }

  Future<void> _deleteEmail(EmailModel email) async {
    try {
      await ref.read(deleteEmailProvider(email.id).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Email supprimé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EmailCard extends StatelessWidget {
  final EmailModel email;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EmailCard({
    required this.email,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(email.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Card(
        elevation: email.isRead ? 0 : 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: email.isRead
              ? BorderSide.none
              : BorderSide(color: Theme.of(context).primaryColor, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête: Expéditeur + Date + Badge importance
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _getImportanceColor(),
                      child: Text(
                        email.displayFrom.isNotEmpty
                            ? email.displayFrom[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nom + Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email.displayFrom,
                            style: TextStyle(
                              fontWeight: email.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            email.displayEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Date + Badge importance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(email.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        _ImportanceBadge(importance: email.aiImportance),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Sujet (gras si non lu)
                Text(
                  email.subject,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: email.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Résumé IA (mis en avant)
                if (email.aiResume != null && email.aiResume!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email.aiResume!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).primaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Catégorie
                if (email.aiCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.label, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          email.aiCategory!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getImportanceColor() {
    switch (email.aiImportance?.toLowerCase()) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return DateFormat('EEE', 'fr').format(date);
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}

class _ImportanceBadge extends StatelessWidget {
  final String? importance;

  const _ImportanceBadge({this.importance});

  @override
  Widget build(BuildContext context) {
    if (importance == null) return const SizedBox.shrink();

    final color = _getColor();
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            importance!,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (importance?.toLowerCase()) {
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

  IconData _getIcon() {
    switch (importance?.toLowerCase()) {
      case 'haute':
        return Icons.priority_high;
      case 'moyenne':
        return Icons.remove;
      case 'faible':
        return Icons.arrow_downward;
      default:
        return Icons.label;
    }
  }
}
