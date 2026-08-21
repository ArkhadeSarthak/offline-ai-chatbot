import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFeedbackService {
  /// Show a non-disruptive Toast pill with haptic feedback
  static void showToast(BuildContext context, String message, {bool isError = false, IconData? icon}) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: isDark ? 8 : 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isError
                ? (isDark ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFFFCA5A5))
                : (isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.2) : const Color(0xFFCBD5E1)),
          ),
        ),
        backgroundColor: isError
            ? (isDark ? const Color(0xFF2A1517) : const Color(0xFFFEF2F2))
            : (isDark ? const Color(0xFF111726) : const Color(0xFFFFFFFF)),
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: isError
                  ? const Color(0xFFEF4444)
                  : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isError
                      ? (isDark ? Colors.white : const Color(0xFF991B1B))
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show Download Confirmation Popup
  static Future<bool> showDownloadConfirmation(
    BuildContext context, {
    required String modelName,
    required double fileSizeGB,
    required double freeStorageGB,
  }) async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF111726) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.12 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prepare Download',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          modelName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow(context, 'Model File Size', '${fileSizeGB.toStringAsFixed(2)} GB'),
                    const SizedBox(height: 8),
                    _buildRow(context, 'Available Storage', '${freeStorageGB.toStringAsFixed(2)} GB'),
                    const SizedBox(height: 8),
                    _buildRow(context, 'Offline Capable', '100% Offline'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Start Download', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// Show Low Memory Warning Dialog (Safe Mode Suggestion)
  static Future<String?> showLowMemoryWarning(
    BuildContext context, {
    required String modelName,
    required String message,
  }) async {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1416) : const Color(0xFFFFF5F5),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: isDark ? 0.15 : 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: isDark ? Colors.orangeAccent : const Color(0xFFD97706),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Memory Is Limited',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF7F1D1D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF991B1B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: Text('Enable Safe Mode (Recommended)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop('safe_mode'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF991B1B),
                      side: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFFCA5A5),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(ctx).pop('continue'),
                    child: Text('Continue Anyway', style: GoogleFonts.inter()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop('cancel'),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show Delete Confirmation Dialog
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required String modelName,
    required double fileSizeGB,
  }) async {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E1416) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: isDark ? 0.15 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Delete Model?',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'This will remove the downloaded GGUF file for $modelName from local storage.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.transparent : const Color(0xFFFEE2E2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Storage to free:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${fileSizeGB.toStringAsFixed(2)} GB',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  static Widget _buildRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
