import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/email_model.dart';
import '../theme/app_theme_2025.dart';

class EmailCard extends StatelessWidget {
  final EmailModel email;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMarkAsUnread;
  final VoidCallback? onMove;
  final VoidCallback? onLongPress;
  final bool showCheckbox;
  final bool isSelected;

  const EmailCard({
    super.key,
    required this.email,
    required this.onTap,
    required this.onDelete,
    this.onMarkAsUnread,
    this.onMove,
    this.onLongPress,
    this.showCheckbox = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRead = email.isRead;

    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      child: Slidable(
        key: ValueKey(email.id),
        // Actions à gauche (swipe vers la droite)
        startActionPane: onMarkAsUnread != null || onMove != null
            ? ActionPane(
                motion: const ScrollMotion(),
                children: [
                  if (email.isRead && onMarkAsUnread != null)
                    SlidableAction(
                      onPressed: (_) {
                        HapticFeedback.mediumImpact();
                        onMarkAsUnread!();
                      },
                      backgroundColor: AppTheme2025.laPosteBlue,
                      foregroundColor: Colors.white,
                      icon: Icons.mark_email_unread_outlined,
                      label: 'Non lu',
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(AppTheme2025.radiusMd),
                      ),
                    ),
                  if (onMove != null)
                    SlidableAction(
                      onPressed: (_) {
                        HapticFeedback.mediumImpact();
                        onMove!();
                      },
                      backgroundColor: AppTheme2025.laPosteYellow,
                      foregroundColor: Colors.black87,
                      icon: Icons.drive_file_move_outlined,
                      label: 'Déplacer',
                    ),
                ],
              )
            : null,
        // Actions à droite (swipe vers la gauche)
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.heavyImpact();
                onDelete();
              },
              backgroundColor: AppTheme2025.error,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Supprimer',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppTheme2025.radiusMd),
              ),
            ),
          ],
        ),
        child: Card(
          elevation: isRead ? 0 : 2,
          color: isSelected
              ? AppTheme2025.laPosteBlue.withOpacity(0.1)
              : (isRead ? theme.colorScheme.surface : Colors.white),
          shadowColor: Colors.black.withOpacity(0.05),
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme2025.sm,
            vertical: AppTheme2025.xxs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme2025.radiusMd),
            side: isSelected
                ? const BorderSide(color: AppTheme2025.laPosteBlue, width: 2)
                : (isRead
                    ? BorderSide.none
                    : BorderSide(color: AppTheme2025.laPosteYellow.withOpacity(0.3), width: 1)),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            onLongPress: onLongPress != null
                ? () {
                    HapticFeedback.mediumImpact();
                    onLongPress!();
                  }
                : null,
            borderRadius: BorderRadius.circular(AppTheme2025.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme2025.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox en mode sélection
                  if (showCheckbox)
                    Padding(
                      padding: const EdgeInsets.only(right: AppTheme2025.sm),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          HapticFeedback.lightImpact();
                          onTap();
                        },
                        activeColor: AppTheme2025.laPosteBlue,
                      ),
                    ),

                  // Avatar
                  _buildAvatar(context),
                  const SizedBox(width: AppTheme2025.md),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                email.displayFrom,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  color: isRead ? theme.colorScheme.onSurface : Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(email.date),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isRead ? Colors.grey : AppTheme2025.laPosteBlue,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.subject,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.aiResume ?? email.body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[400] // Plus clair en mode sombre
                                : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final color = _getImportanceColor();
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            email.displayFrom.isNotEmpty ? email.displayFrom[0].toUpperCase() : '?',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        if (!email.isRead)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme2025.laPosteYellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        if (email.senderTrustStatus == 'blocked')
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block,
                color: AppTheme2025.error,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  Color _getImportanceColor() {
    switch (email.aiImportance?.toLowerCase()) {
      case 'haute':
        return AppTheme2025.importanceHigh;
      case 'moyenne':
        return AppTheme2025.importanceMedium;
      case 'faible':
        return AppTheme2025.importanceLow;
      default:
        return AppTheme2025.laPosteBlue;
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

  String _buildSemanticLabel() {
    final status = email.isRead ? 'Lu' : 'Non lu';
    final importance = email.aiImportance ?? 'normale';
    final date = _formatDate(email.date);
    return '$status. Email de ${email.displayFrom}, importance $importance, reçu $date. ${email.subject}. Touchez pour ouvrir.';
  }
}
