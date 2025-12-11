import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mailbox_model.dart';
import '../providers/email_providers.dart';

class MailboxDrawer extends ConsumerStatefulWidget {
  const MailboxDrawer({super.key});

  @override
  ConsumerState<MailboxDrawer> createState() => _MailboxDrawerState();
}

class _MailboxDrawerState extends ConsumerState<MailboxDrawer> {
  bool _categoriesExpanded = false;
  bool _foldersExpanded = true;

  @override
  Widget build(BuildContext context) {
    final mailboxesAsync = ref.watch(mailboxesProvider);
    final currentMailbox = ref.watch(currentMailboxProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: mailboxesAsync.when(
        data: (mailboxes) => _buildDrawerContent(mailboxes, currentMailbox),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
        error: (error, _) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildDrawerContent(List<MailboxModel> mailboxes, String currentMailbox) {
    // Séparer les dossiers système des dossiers personnalisés
    final systemMailboxes = mailboxes.where((m) => _isSystemFolder(m.path)).toList();
    final customMailboxes = mailboxes.where((m) => !_isSystemFolder(m.path)).toList();

    return Column(
      children: [
        // Header avec design La Poste
        _buildHeader(),

        // Liste scrollable
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // === SECTION 1: MA MESSAGERIE ===
              _buildSectionHeader('MA MESSAGERIE'),
              ...systemMailboxes.map((mailbox) => _buildMailboxTile(mailbox, currentMailbox)),

              const SizedBox(height: 8),

              // === SECTION 2: MES CATÉGORIES (repliable) ===
              _buildExpandableSection(
                title: 'MES CATÉGORIES',
                isExpanded: _categoriesExpanded,
                onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
              ),
              if (_categoriesExpanded) ...[
                _buildCategoryInfo(),
              ],

              const SizedBox(height: 8),

              // === SECTION 3: MES DOSSIERS (repliable avec bouton +) ===
              _buildExpandableSection(
                title: 'MES DOSSIERS',
                isExpanded: _foldersExpanded,
                onToggle: () => setState(() => _foldersExpanded = !_foldersExpanded),
                trailing: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showCreateMailboxDialog(context, ref),
                  tooltip: 'Créer un dossier',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              if (_foldersExpanded) ...[
                if (customMailboxes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Aucun dossier personnalisé',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...customMailboxes.map((mailbox) => _buildMailboxTile(
                        mailbox,
                        currentMailbox,
                        isCustom: true,
                      )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Color(0xFFFFD700), // Jaune La Poste
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.mail, size: 48, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'laposte.net',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'assani.raffion@laposte.net',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(mailboxesProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Actualisation des dossiers...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Colors.black87),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD700), // Jaune La Poste
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.grey[100],
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 20,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInfo() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Les catégories sont gérées automatiquement dans l\'onglet Smart Inbox (Personnel, Notifs, News)',
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMailboxTile(
    MailboxModel mailbox,
    String currentMailbox, {
    bool isCustom = false,
  }) {
    final isSelected = mailbox.path == currentMailbox;
    final displayName = _getMailboxDisplayName(mailbox.path);

    return ListTile(
      selected: isSelected,
      selectedColor: const Color(0xFFFFD700), // Couleur primaire (jaune) pour icône et texte
      selectedTileColor: const Color(0xFFFFF9E6), // Jaune très pâle pour le fond
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Formes arrondies
      ),
      leading: Icon(
        _getMailboxIcon(mailbox),
        color: isSelected ? const Color(0xFFFFD700) : Colors.black54,
        size: 22,
      ),
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF1A1A2E) : Colors.black87,
          fontSize: 14,
        ),
      ),
      subtitle: mailbox.messageCount > 0
          ? Text(
              '${mailbox.messageCount} message(s)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            )
          : null,
      trailing: mailbox.unseenCount > 0
          ? Badge(
              label: Text('${mailbox.unseenCount}'),
              backgroundColor: const Color(0xFFFFD700),
              textColor: Colors.black87,
            )
          : null,
      onTap: () => _selectMailbox(mailbox),
      onLongPress: isCustom ? () => _showMailboxOptionsDialog(context, ref, mailbox) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _selectMailbox(MailboxModel mailbox) {
    // Changer de dossier
    ref.read(currentMailboxProvider.notifier).state = mailbox.path;

    // Synchroniser les emails du nouveau dossier
    ref.invalidate(syncMailboxEmailsProvider(mailbox.path));

    // Fermer le drawer
    Navigator.pop(context);

    // Afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📂 ${_getMailboxDisplayName(mailbox.path)}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getMailboxDisplayName(String path) {
    // Traduction des dossiers système
    if (path == 'INBOX') return 'Réception';

    // Enlever le préfixe INBOX/
    String cleanPath = path;
    if (path.startsWith('INBOX/')) {
      cleanPath = path.substring(6);
    }

    final lowerPath = cleanPath.toLowerCase();

    // Traductions des dossiers standards
    if (lowerPath.contains('sent') || lowerPath == 'sent') return 'Envoyés';
    if (lowerPath.contains('trash') || lowerPath == 'trash') return 'Corbeille';
    if (lowerPath.contains('junk') || lowerPath.contains('spam')) return 'Indésirables';
    if (lowerPath.contains('drafts') || lowerPath == 'drafts') return 'Brouillons';
    if (lowerPath.contains('archive') || lowerPath == 'archive') return 'Archive';
    if (lowerPath.contains('outbox')) return 'Boîte d\'envoi';

    // Pour les dossiers personnalisés, remplacer / par >
    return cleanPath.replaceAll('/', ' > ');
  }

  IconData _getMailboxIcon(MailboxModel mailbox) {
    if (mailbox.isInbox) return Icons.inbox;
    if (mailbox.isSent) return Icons.send;
    if (mailbox.isTrash) return Icons.delete;
    if (mailbox.isSpam) return Icons.report;
    if (mailbox.isDrafts) return Icons.drafts;
    if (mailbox.isArchive) return Icons.archive;
    return Icons.folder;
  }

  bool _isSystemFolder(String path) {
    final lowerPath = path.toLowerCase();
    return path == 'INBOX' ||
        lowerPath.contains('sent') ||
        lowerPath.contains('trash') ||
        lowerPath.contains('deleted') ||
        lowerPath.contains('spam') ||
        lowerPath.contains('junk') ||
        lowerPath.contains('drafts') ||
        lowerPath.contains('outbox') ||
        lowerPath.contains('archive');
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(mailboxesProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // === Dialogues ===

  void _showCreateMailboxDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un nouveau dossier'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du dossier',
            hintText: 'Ex: Factures, Personnel...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final folderName = controller.text.trim();
              if (folderName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Le nom ne peut pas être vide')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ref.read(createMailboxProvider(folderName).future);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Dossier "$folderName" créé')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showMailboxOptionsDialog(
      BuildContext context, WidgetRef ref, MailboxModel mailbox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getMailboxDisplayName(mailbox.path)),
        content: const Text('Que souhaitez-vous faire avec ce dossier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showRenameMailboxDialog(context, ref, mailbox);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Renommer'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteMailbox(context, ref, mailbox);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRenameMailboxDialog(
      BuildContext context, WidgetRef ref, MailboxModel mailbox) {
    final controller = TextEditingController(text: mailbox.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le dossier'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Le nom ne peut pas être vide')),
                );
                return;
              }

              if (newName == mailbox.name) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(context);

              try {
                await ref.read(renameMailboxProvider({
                  'oldPath': mailbox.path,
                  'newPath': newName,
                }).future);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Dossier renommé en "$newName"')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMailbox(
      BuildContext context, WidgetRef ref, MailboxModel mailbox) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce dossier ?'),
        content: Text(
          'Le dossier "${_getMailboxDisplayName(mailbox.path)}" et tous ses emails seront supprimés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref.read(deleteMailboxProvider(mailbox.path).future);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Dossier "${_getMailboxDisplayName(mailbox.path)}" supprimé'),
                    ),
                  );

                  // Retourner à INBOX si on était dans le dossier supprimé
                  if (ref.read(currentMailboxProvider) == mailbox.path) {
                    ref.read(currentMailboxProvider.notifier).state = 'INBOX';
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
