import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mailbox_model.dart';
import '../providers/email_providers.dart';

class MoveEmailSheet extends ConsumerWidget {
  final int emailId;

  const MoveEmailSheet({
    super.key,
    required this.emailId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mailboxesAsync = ref.watch(mailboxesProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.drive_file_move_outlined, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Déplacer vers...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Liste des dossiers
          mailboxesAsync.when(
            data: (mailboxes) {
              if (mailboxes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucun dossier disponible'),
                );
              }

              return Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mailboxes.length,
                  itemBuilder: (context, index) {
                    final mailbox = mailboxes[index];
                    return ListTile(
                      leading: Icon(_getMailboxIcon(mailbox.path)),
                      title: Text(_getMailboxDisplayName(mailbox.path)),
                      subtitle: mailbox.messageCount > 0
                          ? Text('${mailbox.messageCount} emails')
                          : null,
                      onTap: () async {
                        Navigator.pop(context);

                        // Afficher un loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('📦 Déplacement en cours...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        try {
                          // Déplacer l'email
                          await ref.read(moveEmailProvider({
                            'emailId': emailId,
                            'targetFolder': mailbox.path,
                          }).future);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Email déplacé vers ${_getMailboxDisplayName(mailbox.path)}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Erreur: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMailboxIcon(String path) {
    final lowerPath = path.toLowerCase();

    if (path == 'INBOX') return Icons.inbox;
    if (lowerPath.contains('sent')) return Icons.send;
    if (lowerPath.contains('trash') || lowerPath.contains('deleted')) {
      return Icons.delete;
    }
    if (lowerPath.contains('draft')) return Icons.drafts;
    if (lowerPath.contains('junk') || lowerPath.contains('spam')) {
      return Icons.report;
    }
    if (lowerPath.contains('archive')) return Icons.archive;

    return Icons.folder;
  }

  String _getMailboxDisplayName(String path) {
    if (path == 'INBOX') return 'Boîte de réception';

    // Enlever le préfixe INBOX/ si présent
    String displayPath = path;
    if (path.startsWith('INBOX/')) {
      displayPath = path.substring(6);
    }

    // Mapper les noms communs
    final lowerPath = displayPath.toLowerCase();
    if (lowerPath.contains('sent')) return 'Envoyés';
    if (lowerPath.contains('trash')) return 'Corbeille';
    if (lowerPath.contains('junk') || lowerPath.contains('spam')) return 'Spam';
    if (lowerPath.contains('drafts')) return 'Brouillons';
    if (lowerPath.contains('archive')) return 'Archives';

    // Remplacer / par > pour hiérarchie visuelle
    return displayPath.replaceAll('/', ' > ');
  }
}
