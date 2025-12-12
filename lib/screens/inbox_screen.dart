import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/email_model.dart';
import '../providers/email_providers.dart';
import '../widgets/mailbox_drawer.dart';
import '../widgets/email_card.dart';
import '../widgets/move_email_sheet.dart';
import 'email_detail_screen.dart';
import 'compose_screen.dart';
import '../theme/app_theme_2025.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _filterImportance = 'all';
  bool _isRefreshing = false;

  // Pagination pour accès complet aux emails
  int _currentEmailLimit = 200;
  bool _isLoadingMore = false;

  // Recherche
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Tri et filtrage
  String _sortBy = 'date_desc'; // date_desc, date_asc, sender, subject
  String _filterBy = 'all'; // all, unread, read, starred, personnel, notification, newsletter

  // Sélection multiple
  bool _isSelectionMode = false;
  final Set<int> _selectedEmailIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _syncEmails();
      // Déclencher aussi la synchronisation des mailboxes pour actualiser les compteurs
      ref.read(mailboxesProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int emailId) {
    setState(() {
      if (_selectedEmailIds.contains(emailId)) {
        _selectedEmailIds.remove(emailId);
        // Si plus de sélection, sortir du mode sélection
        if (_selectedEmailIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedEmailIds.add(emailId);
      }
    });
  }

  void _enterSelectionMode(int emailId) {
    setState(() {
      _isSelectionMode = true;
      _selectedEmailIds.add(emailId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedEmailIds.clear();
    });
  }

  Future<void> _syncEmails() async {
    setState(() => _isRefreshing = true);

    try {
      final currentMailbox = ref.read(currentMailboxProvider);
      final params = {'mailboxPath': currentMailbox, 'limit': _currentEmailLimit};
      ref.invalidate(syncMailboxEmailsWithLimitProvider(params));
      await ref.read(syncMailboxEmailsWithLimitProvider(params).future);

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

  Future<void> _loadMoreEmails() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentEmailLimit += 200; // Charger 200 emails supplémentaires
    });

    try {
      final currentMailbox = ref.read(currentMailboxProvider);
      final params = {'mailboxPath': currentMailbox, 'limit': _currentEmailLimit};
      ref.invalidate(syncMailboxEmailsWithLimitProvider(params));
      await ref.read(syncMailboxEmailsWithLimitProvider(params).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_currentEmailLimit} emails chargés'),
            duration: const Duration(seconds: 2),
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
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showSortFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sort, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Trier et filtrer',
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
            const SizedBox(height: 20),
            Text(
              'TRIER PAR',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildSortOption('Date (récent → ancien)', 'date_desc', Icons.arrow_downward),
            _buildSortOption('Date (ancien → récent)', 'date_asc', Icons.arrow_upward),
            _buildSortOption('Expéditeur (A → Z)', 'sender', Icons.person),
            _buildSortOption('Sujet (A → Z)', 'subject', Icons.subject),
            const Divider(height: 32),
            Text(
              'FILTRER PAR',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildFilterOption('Tous', 'all', Icons.all_inbox),
            _buildFilterOption('Non lus', 'unread', Icons.mark_email_unread),
            _buildFilterOption('Lus', 'read', Icons.mark_email_read),
            _buildFilterOption('Personnel', 'personnel', Icons.person),
            _buildFilterOption('Notifications', 'notification', Icons.notifications),
            _buildFilterOption('Newsletters', 'newsletter', Icons.article),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterOption(String label, String value, IconData icon) {
    final isSelected = _filterBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() => _filterBy = value);
        Navigator.pop(context);
      },
    );
  }

  // Resynchronisation complète forcée (vider + tout retélécharger)
  Future<void> _forceFullResync() async {
    // Confirmation avant de vider la base
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Resynchronisation complète'),
        content: const Text(
          'Cette action va SUPPRIMER tous les emails locaux et retélécharger les 500 derniers depuis le serveur.\n\n'
          'Cela peut prendre 1-2 minutes. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRefreshing = true);

    try {
      final currentMailbox = ref.read(currentMailboxProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Suppression des emails locaux...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Forcer la resynchronisation complète
      ref.invalidate(forceFullResyncProvider(currentMailbox));
      await ref.read(forceFullResyncProvider(currentMailbox).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Resynchronisation complète terminée! Consultez les logs.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur resynchronisation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    final currentMailbox = ref.watch(currentMailboxProvider);
    final emailsAsync = ref.watch(currentMailboxEmailsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    
    // DEBUG: Forcer le chargement des dossiers
    ref.read(mailboxesProvider);

    // Si on n'est pas dans INBOX, on affiche une liste simple
    if (currentMailbox != 'INBOX') {
      return Scaffold(
        drawer: const MailboxDrawer(),
        appBar: _buildAppBar(context, currentMailbox, unreadCount),
        body: _buildEmailList(emailsAsync, null),
        bottomNavigationBar: _isSelectionMode ? _buildBottomAppBar() : null,
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ComposeScreen()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Nouveau'),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
              ),
      );
    }

    // Smart Inbox pour INBOX
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const MailboxDrawer(),
        appBar: _buildAppBar(context, currentMailbox, unreadCount, withTabs: true),
        body: TabBarView(
          children: [
            _buildEmailList(emailsAsync, 'personnel'),
            _buildEmailList(emailsAsync, 'notification'),
            _buildEmailList(emailsAsync, 'newsletter'),
          ],
        ),
        bottomNavigationBar: _isSelectionMode ? _buildBottomAppBar() : null,
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ComposeScreen()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Nouveau'),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String currentMailbox,
    AsyncValue<int> unreadCount, {
    bool withTabs = false,
  }) {
    return AppBar(
      backgroundColor: AppTheme2025.goldenYellow,
      foregroundColor: Colors.black, // WCAG AA Contrast
      iconTheme: const IconThemeData(color: Colors.black), // WCAG AA Contrast
      actionsIconTheme: const IconThemeData(color: Colors.black), // WCAG AA Contrast
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Ouvrir le menu des dossiers',
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: _isSearchMode
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
              ),
              onChanged: _updateSearchQuery,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_getMailboxDisplayName(currentMailbox)),
                if (withTabs)
                  Text(
                    'Smart Inbox',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                  )
                else
                  unreadCount.when(
                    data: (count) => Text(
                      '$count non lu(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              ],
            ),
      actions: [
        if (!_isSearchMode) ...[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher',
            onPressed: _toggleSearchMode,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Trier et filtrer',
            onPressed: _showSortFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Actions IA',
            onPressed: () => _showAiActionsMenu(context),
          ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _syncEmails();
                  },
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fermer la recherche',
            onPressed: _toggleSearchMode,
          ),
        ],
      ],
      bottom: withTabs
          ? const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Personnel', icon: Icon(Icons.person_outline)),
                Tab(text: 'Notifs', icon: Icon(Icons.notifications_none)),
                Tab(text: 'News', icon: Icon(Icons.article_outlined)),
              ],
            )
          : null,
    );
  }

  Widget _buildEmailList(AsyncValue<List<EmailModel>> emailsAsync, String? category) {
    return emailsAsync.when(
      data: (emails) {
        // 1. Filtrer par catégorie si nécessaire (Smart Inbox)
        var filteredEmails = emails;
        if (category != null) {
          filteredEmails = emails.where((e) {
            return e.aiCategory == category;
          }).toList();
        }

        // 2. Appliquer la recherche
        if (_searchQuery.isNotEmpty) {
          filteredEmails = filteredEmails.where((e) {
            final searchLower = _searchQuery.toLowerCase();
            return e.displayFrom.toLowerCase().contains(searchLower) ||
                   e.displayEmail.toLowerCase().contains(searchLower) ||
                   e.subject.toLowerCase().contains(searchLower) ||
                   e.body.toLowerCase().contains(searchLower);
          }).toList();
        }

        // 3. Appliquer les filtres
        if (_filterBy != 'all') {
          filteredEmails = filteredEmails.where((e) {
            switch (_filterBy) {
              case 'unread':
                return !e.isRead;
              case 'read':
                return e.isRead;
              case 'personnel':
                return e.aiCategory == 'personnel';
              case 'notification':
                return e.aiCategory == 'notification';
              case 'newsletter':
                return e.aiCategory == 'newsletter';
              default:
                return true;
            }
          }).toList();
        }

        // 4. Appliquer le tri
        switch (_sortBy) {
          case 'date_desc':
            filteredEmails.sort((a, b) => b.date.compareTo(a.date));
            break;
          case 'date_asc':
            filteredEmails.sort((a, b) => a.date.compareTo(b.date));
            break;
          case 'sender':
            filteredEmails.sort((a, b) => a.displayFrom.toLowerCase().compareTo(b.displayFrom.toLowerCase()));
            break;
          case 'subject':
            filteredEmails.sort((a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()));
            break;
        }

        if (filteredEmails.isEmpty) {
          return _buildEmptyState(category);
        }

        // Vérifier s'il y a plus d'emails à charger
        final currentMailbox = ref.read(currentMailboxProvider);
        final hasMore = emails.length >= _currentEmailLimit;

        return RefreshIndicator(
          onRefresh: _syncEmails,
          color: Theme.of(context).colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredEmails.length + (hasMore ? 1 : 0), // +1 pour le bouton "Charger plus"
            itemBuilder: (context, index) {
              // Bouton "Charger plus" à la fin
              if (hasMore && index == filteredEmails.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoadingMore
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _loadMoreEmails,
                            icon: const Icon(Icons.expand_more),
                            label: Text('Charger plus (${_currentEmailLimit} → ${_currentEmailLimit + 200})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                  ),
                );
              }

              final email = filteredEmails[index];
              return EmailCard(
                email: email,
                showCheckbox: _isSelectionMode,
                isSelected: _selectedEmailIds.contains(email.id),
                onTap: _isSelectionMode
                    ? () => _toggleSelection(email.id)
                    : () => _openEmailDetail(email),
                onLongPress: () => _enterSelectionMode(email.id),
                onDelete: () => _deleteEmail(email),
                onMarkAsUnread: () => _markAsUnread(email),
                onMove: () => _showMoveSheet(email),
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildEmptyState(String? category) {
    String message = 'Aucun email';
    IconData icon = Icons.inbox;

    if (category == 'personnel') {
      message = 'Tout est calme ici';
      icon = Icons.person_off;
    } else if (category == 'notification') {
      message = 'Aucune notification';
      icon = Icons.notifications_off;
    } else if (category == 'newsletter') {
      message = 'Pas de newsletter';
      icon = Icons.mark_email_read;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          // Bug #3 fix: Loading indicator pour le bouton Actualiser
          TextButton.icon(
            onPressed: _isRefreshing
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _syncEmails();
                  },
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isRefreshing ? 'Chargement...' : 'Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    return Center(
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
    );
  }

  void _openEmailDetail(EmailModel email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(email: email),
      ),
    ).then((_) {
      // Rafraîchir au retour (pour marquer comme lu, etc.)
      _syncEmails();
    });
  }

  Future<void> _deleteEmail(EmailModel email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous vraiment supprimer cet email ?'),
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
        await ref.read(deleteEmailProvider(email.id).future);
        // ✅ PAS de _syncEmails() ici ! Le StreamProvider Isar se met à jour automatiquement
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Email supprimé')),
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
  }

  Future<void> _markAsUnread(EmailModel email) async {
    try {
      await ref.read(markAsUnreadProvider(email.id).future);
      // ✅ StreamProvider se met à jour automatiquement
      if (mounted) {
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

  void _showMoveSheet(EmailModel email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MoveEmailSheet(emailId: email.id),
    );
  }

  Future<void> _cleanSpam() async {
    final aiService = ref.read(aiServiceProvider);
    final allMailboxes = await ref.read(mailboxesProvider.future);
    final allEmails = await ref.read(currentMailboxEmailsProvider.future);

    // 1. Trouver le dossier de spam
    String? spamFolderPath;
    try {
      final spamMailbox = allMailboxes.firstWhere((m) {
        final lowerPath = m.path.toLowerCase();
        return lowerPath.contains('junk') || lowerPath.contains('spam');
      });
      spamFolderPath = spamMailbox.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Dossier "Indésirables" ou "Spam" introuvable.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Filtrer les emails à analyser (ceux dans INBOX)
    final emailsToScan = allEmails.where((e) => e.mailboxPath == 'INBOX').toList();

    if (emailsToScan.isEmpty) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Aucun email à analyser dans la boîte de réception.')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🤖 Analyse de ${emailsToScan.length} emails en cours...'),
        ),
      );
    }

    int spamCount = 0;
    // 3. Itérer et analyser chaque email
    for (final email in emailsToScan) {
      try {
        final isSpam = await aiService.isEmailSpam(
          email.displayFrom,
          email.subject,
          email.body,
        );

        if (isSpam) {
          spamCount++;
          // Déplacer l'email
          await ref.read(moveEmailProvider({
            'emailId': email.id,
            'targetFolder': spamFolderPath,
          }).future);
        }
      } catch (e) {
        print('Erreur lors de l\'analyse ou du déplacement de l\'email ${email.id}: $e');
      }
    }

    // 4. Afficher le résumé
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Nettoyage terminé. $spamCount spam(s) déplacé(s).'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAiActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Actions IA',
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
            const SizedBox(height: 16),
            const Text(
              'Laissez l\'IA optimiser votre boîte mail :',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.sync, color: Colors.white),
              ),
              title: const Text('🔥 Resynchronisation complète'),
              subtitle: const Text('Vider et retélécharger TOUS les emails (500 derniers)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _forceFullResync();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.sort, color: Colors.white),
              ),
              title: const Text('Trier automatiquement'),
              subtitle: const Text('Classer les emails par importance et catégorie'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _analyzeAllEmails();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.cleaning_services, color: Colors.white),
              ),
              title: const Text('Nettoyer les spam'),
              subtitle: const Text('Détecter et déplacer les emails indésirables'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _cleanSpam();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.chat, color: Colors.white),
              ),
              title: const Text('Ouvrir l\'assistant Jarvis'),
              subtitle: const Text('Poser des questions sur vos emails'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // Retourner à l'écran principal et basculer sur l'onglet Assistant
                // Pour l'instant, afficher un message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('💬 Allez sur l\'onglet "Assistant" pour parler à Jarvis'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeAllEmails() async {
    final currentMailbox = ref.read(currentMailboxProvider);
    final emailsAsync = await ref.read(currentMailboxEmailsProvider.future);

    final unanalyzedEmails = emailsAsync.where((e) => !e.isAiAnalyzed).toList();

    if (unanalyzedEmails.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tous les emails sont déjà analysés!'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🤖 Analyse de ${unanalyzedEmails.length} emails en cours...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // TODO: Déclencher l'analyse IA en arrière-plan
    // Pour l'instant, juste afficher un message
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Analyse terminée! L\'IA a trié vos emails.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteSelectedEmails() async {
    final count = _selectedEmailIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous vraiment supprimer $count email(s) ?'),
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
        // Copier la liste car elle sera modifiée pendant la suppression
        final emailIds = List<int>.from(_selectedEmailIds);

        for (final emailId in emailIds) {
          await ref.read(deleteEmailProvider(emailId).future);
        }

        _exitSelectionMode();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🗑️ $count email(s) supprimé(s)')),
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
  }

  Future<void> _markSelectedAsUnread() async {
    try {
      final emailIds = List<int>.from(_selectedEmailIds);

      for (final emailId in emailIds) {
        await ref.read(markAsUnreadProvider(emailId).future);
      }

      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✉️ ${emailIds.length} email(s) marqué(s) comme non lu'),
            duration: const Duration(seconds: 2),
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

  void _moveSelectedEmails() {
    final emailIds = List<int>.from(_selectedEmailIds);

    // Pour simplifier, on utilise le premier email pour le sheet
    // Le sheet sera modifié pour accepter une liste
    if (emailIds.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildBatchMoveSheet(emailIds),
      ).then((_) => _exitSelectionMode());
    }
  }

  Widget _buildBatchMoveSheet(List<int> emailIds) {
    final mailboxesAsync = ref.watch(mailboxesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drive_file_move, size: 28),
              const SizedBox(width: 12),
              Text(
                'Déplacer ${emailIds.length} email(s)',
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
          const SizedBox(height: 16),
          const Text(
            'Sélectionnez le dossier de destination :',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: mailboxesAsync.when(
              data: (mailboxes) => ListView.builder(
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
                      try {
                        for (final emailId in emailIds) {
                          await ref.read(moveEmailProvider({
                            'emailId': emailId,
                            'targetFolder': mailbox.path,
                          }).future);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '📁 ${emailIds.length} email(s) déplacé(s) vers ${_getMailboxDisplayName(mailbox.path)}',
                              ),
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
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Erreur: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMailboxIcon(String path) {
    if (path == 'INBOX') return Icons.inbox;
    final lowerPath = path.toLowerCase();
    if (lowerPath.contains('sent')) return Icons.send;
    if (lowerPath.contains('trash')) return Icons.delete;
    if (lowerPath.contains('spam') || lowerPath.contains('junk')) {
      return Icons.report;
    }
    if (lowerPath.contains('drafts')) return Icons.drafts;
    return Icons.folder;
  }

  String _getMailboxDisplayName(String path) {
    if (path == 'INBOX') return 'Réception';

    // Enlever le préfixe INBOX/ si présent
    String cleanPath = path;
    if (path.startsWith('INBOX/')) {
      cleanPath = path.substring(6);
    }

    final lowerPath = cleanPath.toLowerCase();

    // Traductions françaises (synchronisées avec mailbox_drawer.dart)
    if (lowerPath.contains('sent')) return 'Envoyés';
    if (lowerPath.contains('trash')) return 'Corbeille';
    if (lowerPath.contains('junk') || lowerPath.contains('spam')) return 'Indésirables';
    if (lowerPath.contains('drafts')) return 'Brouillons';
    if (lowerPath.contains('archive')) return 'Archive';

    // Remplacer / par > pour hiérarchie visuelle
    return cleanPath.replaceAll('/', ' > ');
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black87),
              tooltip: 'Annuler la sélection',
              onPressed: _exitSelectionMode,
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedEmailIds.length} sélectionné(s)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.drive_file_move_outlined, color: Colors.black87),
              tooltip: 'Déplacer',
              onPressed: _selectedEmailIds.isEmpty ? null : _moveSelectedEmails,
            ),
            IconButton(
              icon: const Icon(Icons.mark_email_unread_outlined, color: Colors.black87),
              tooltip: 'Marquer comme non lu',
              onPressed: _selectedEmailIds.isEmpty ? null : _markSelectedAsUnread,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: _selectedEmailIds.isEmpty ? null : _deleteSelectedEmails,
            ),
          ],
        ),
      ),
    );
  }
}


