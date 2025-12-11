import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme_2025.dart';

/// 🧩 Composants Réutilisables 2025
/// Basés sur Material Design 3 et accessibilité WCAG

// ============================================================================
// BOUTONS
// ============================================================================

enum ButtonVariant { filled, tonal, outlined, text }
enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final String? semanticLabel;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Tailles selon Material 3
    final double height = switch (size) {
      ButtonSize.small => 32.0,
      ButtonSize.medium => 40.0,
      ButtonSize.large => 48.0,
    };

    final double fontSize = switch (size) {
      ButtonSize.small => 12.0,
      ButtonSize.medium => 14.0,
      ButtonSize.large => 16.0,
    };

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(AppTheme2025.minTouchTarget, height),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
    );

    Widget buildButton() {
      if (isLoading) {
        return _buildLoadingButton(context, height);
      }

      return switch (variant) {
        ButtonVariant.filled => icon != null
            ? FilledButton.icon(
                style: buttonStyle,
                onPressed: onPressed,
                icon: Icon(icon, size: fontSize * 1.4),
                label: Text(label),
              )
            : FilledButton(
                style: buttonStyle,
                onPressed: onPressed,
                child: Text(label),
              ),
        ButtonVariant.tonal => icon != null
            ? FilledButton.tonalIcon(
                style: buttonStyle,
                onPressed: onPressed,
                icon: Icon(icon, size: fontSize * 1.4),
                label: Text(label),
              )
            : FilledButton.tonal(
                style: buttonStyle,
                onPressed: onPressed,
                child: Text(label),
              ),
        ButtonVariant.outlined => icon != null
            ? OutlinedButton.icon(
                style: buttonStyle,
                onPressed: onPressed,
                icon: Icon(icon, size: fontSize * 1.4),
                label: Text(label),
              )
            : OutlinedButton(
                style: buttonStyle,
                onPressed: onPressed,
                child: Text(label),
              ),
        ButtonVariant.text => icon != null
            ? TextButton.icon(
                style: buttonStyle,
                onPressed: onPressed,
                icon: Icon(icon, size: fontSize * 1.4),
                label: Text(label),
              )
            : TextButton(
                style: buttonStyle,
                onPressed: onPressed,
                child: Text(label),
              ),
      };
    }

    // Accessibilité WCAG
    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: buildButton(),
    );
  }

  Widget _buildLoadingButton(BuildContext context, double height) {
    return FilledButton(
      onPressed: null,
      child: SizedBox(
        width: height * 0.6,
        height: height * 0.6,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

// ============================================================================
// CARDS
// ============================================================================

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final double? elevation;
  final Color? color;
  final String? semanticLabel;
  final bool enableHaptics;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppTheme2025.md),
    this.elevation,
    this.color,
    this.semanticLabel,
    this.enableHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Card(
        elevation: elevation ?? AppTheme2025.level1,
        color: color,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  if (enableHaptics) {
                    HapticFeedback.lightImpact();
                  }
                  onTap!();
                }
              : null,
          onLongPress: onLongPress != null
              ? () {
                  if (enableHaptics) {
                    HapticFeedback.mediumImpact();
                  }
                  onLongPress!();
                }
              : null,
          borderRadius: BorderRadius.circular(AppTheme2025.radiusMd),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ÉTATS VIDES
// ============================================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. ${subtitle ?? ''}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme2025.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 80,
                  color: context.colors.outline.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: AppTheme2025.lg),
              Text(
                title,
                style: context.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme2025.sm),
                Text(
                  subtitle!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppTheme2025.xl),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: ButtonVariant.filled,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING STATES
// ============================================================================

class LoadingState extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;

  const LoadingState({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }
    return child;
  }
}

/// Skeleton loader pour listes
class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ListView.builder(
        itemCount: widget.itemCount,
        padding: const EdgeInsets.all(AppTheme2025.md),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme2025.sm),
            child: _SkeletonItem(
              animation: _animation,
              height: widget.itemHeight,
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonItem extends AnimatedWidget {
  final double height;

  const _SkeletonItem({
    required Animation<double> animation,
    required this.height,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest
            .withOpacity(animation.value),
        borderRadius: BorderRadius.circular(AppTheme2025.radiusMd),
      ),
    );
  }
}

// ============================================================================
// ERROR STATES
// ============================================================================

class ErrorState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.actionLabel = 'Réessayer',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Erreur: $message',
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme2025.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 64,
                  color: context.colors.error,
                ),
              ),
              const SizedBox(height: AppTheme2025.lg),
              Text(
                message,
                style: context.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppTheme2025.xl),
                AppButton(
                  label: actionLabel!,
                  onPressed: onRetry,
                  icon: Icons.refresh,
                  variant: ButtonVariant.filled,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BADGES
// ============================================================================

enum BadgeVariant { success, warning, error, info, neutral }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = _getColors(context);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme2025.sm,
          vertical: AppTheme2025.xxs,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme2025.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Icon(icon, size: 12, color: foregroundColor),
              ),
              const SizedBox(width: AppTheme2025.xxs),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _getColors(BuildContext context) {
    return switch (variant) {
      BadgeVariant.success => (
          AppTheme2025.success.withOpacity(0.2),
          AppTheme2025.success
        ),
      BadgeVariant.warning => (
          AppTheme2025.warning.withOpacity(0.2),
          AppTheme2025.warning
        ),
      BadgeVariant.error => (
          AppTheme2025.error.withOpacity(0.2),
          AppTheme2025.error
        ),
      BadgeVariant.info => (
          AppTheme2025.info.withOpacity(0.2),
          AppTheme2025.info
        ),
      BadgeVariant.neutral => (
          context.colors.surfaceContainerHighest,
          context.colors.onSurface
        ),
    };
  }
}

// ============================================================================
// AVATARS
// ============================================================================

class AppAvatar extends StatelessWidget {
  final String text;
  final double size;
  final Color? backgroundColor;
  final String? imageUrl;
  final IconData? icon;

  const AppAvatar({
    super.key,
    required this.text,
    this.size = 40,
    this.backgroundColor,
    this.imageUrl,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ??
        _generateColorFromString(text, context.colors.primary);

    return Semantics(
      label: 'Avatar de $text',
      image: true,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? icon != null
                ? ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: size * 0.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    text.isNotEmpty ? text[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
            : null,
      ),
    );
  }

  Color _generateColorFromString(String str, Color baseColor) {
    if (str.isEmpty) return baseColor;

    final hash = str.codeUnits.fold(0, (prev, curr) => prev + curr);
    final hue = (hash % 360).toDouble();

    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }
}

// ============================================================================
// ACCESSIBILITY HELPERS
// ============================================================================

/// Widget pour zones tactiles minimum 48x48dp (WCAG)
class AccessibleTapArea extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AccessibleTapArea({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppTheme2025.minTouchTarget,
            minHeight: AppTheme2025.minTouchTarget,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// Extension pour faciliter l'usage
extension BuildContextExtension on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
