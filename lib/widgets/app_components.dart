import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Standardized card container with subtle borders and optional tap feedback
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;

  const AppCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14.0,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bg = backgroundColor ??
        (isDark ? const Color(0xFF111726) : const Color(0xFFFFFFFF));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    final cardChild = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 2),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardChild,
      );
    }

    return cardChild;
  }
}

/// Standardized button component with primary, secondary, and outline styles
enum AppButtonStyle { primary, secondary, outline, danger, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;

    switch (style) {
      case AppButtonStyle.primary:
        bg = theme.colorScheme.primary;
        fg = isDark ? Colors.black : Colors.white;
        break;
      case AppButtonStyle.secondary:
        bg = isDark ? const Color(0xFF182035) : const Color(0xFFF1F5F9);
        fg = theme.colorScheme.onSurface;
        side = BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
        );
        break;
      case AppButtonStyle.outline:
        bg = Colors.transparent;
        fg = theme.colorScheme.primary;
        side = BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5));
        break;
      case AppButtonStyle.danger:
        bg = const Color(0xFFEF4444);
        fg = Colors.white;
        break;
      case AppButtonStyle.text:
        bg = Colors.transparent;
        fg = theme.colorScheme.primary;
        break;
    }

    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    );

    final buttonWidget = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: side,
        ),
      ),
      onPressed: (onPressed == null || isLoading)
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      child: child,
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: buttonWidget) : buttonWidget;
  }
}

/// Compact status badge pill
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isOutline;

  const AppStatusBadge({
    Key? key,
    required this.label,
    required this.color,
    this.icon,
    this.isOutline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isOutline ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header widget
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;

  const AppSectionHeader({
    Key? key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onActionTap != null)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onActionTap!();
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Polished Empty State component
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const AppEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, size: 36, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 20),
            AppButton(
              label: actionLabel!,
              onPressed: onActionTap,
              style: AppButtonStyle.primary,
            ),
          ],
        ],
      ),
    ),
  );
  }
}

/// Polished Error State component
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    Key? key,
    this.title = 'Operation Failed',
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: const Color(0xFF2A1517),
      borderColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onRetry,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF00E5FF)),
                        const SizedBox(width: 4),
                        Text(
                          'Try Again',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E5FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
