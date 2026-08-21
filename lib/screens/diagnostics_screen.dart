import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/model_app_state.dart';
import '../widgets/app_components.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final modelAppState = Provider.of<ModelAppState>(context);
    final llmService = modelAppState.llmService;
    final diag = llmService.getDiagnostics();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Engine Diagnostics',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatusHeader(diag, llmService.activeModelName, theme, isDark),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Active Engine State'),
          _buildInfoTile('Model Path', diag.activeModelPath ?? 'None', theme),
          _buildInfoTile('Active Model', llmService.activeModelName, theme),
          _buildInfoTile('Chat Template', llmService.activeChatTemplate.toUpperCase(), theme),
          _buildInfoTile('Engine Loaded', diag.isLoaded ? 'YES' : 'NO', theme, isAccent: diag.isLoaded),
          _buildInfoTile('Last Stage Marker', diag.lastCrashMarker, theme),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Performance & Metrics'),
          _buildInfoTile('Tokens / Second', '${diag.tokensPerSecond.toStringAsFixed(1)} t/s', theme),
          _buildInfoTile('First Token Latency', diag.lastFirstTokenLatency, theme),
          _buildInfoTile('Last Token Count', '${diag.lastTokenCount} tokens', theme),
          _buildInfoTile('Inference Time', '${diag.lastInferenceDurationMs} ms', theme),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Hardware Allocation'),
          _buildInfoTile('Context Window (nCtx)', '${diag.activeContextSize} tokens', theme),
          _buildInfoTile('CPU Threads', '${diag.activeThreadCount} threads', theme),
          _buildInfoTile('Temperature', '${modelAppState.inferenceSettings.temperature}', theme),
          _buildInfoTile('Top P / Top K', '${modelAppState.inferenceSettings.topP} / ${modelAppState.inferenceSettings.topK}', theme),
          _buildInfoTile('Repeat Penalty', '${modelAppState.inferenceSettings.repeatPenalty}', theme),
          if (diag.lastError != null) ...[
            const SizedBox(height: 20),
            const AppSectionHeader(title: 'Last Error Log'),
            AppCard(
              backgroundColor: const Color(0xFF2A1517),
              borderColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
              child: SelectableText(
                diag.lastError!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeader(diag, String modelName, ThemeData theme, bool isDark) {
    final isLoaded = diag.isLoaded;
    final statusColor = isLoaded ? const Color(0xFF10B981) : theme.colorScheme.primary;

    return AppCard(
      backgroundColor: isLoaded
          ? statusColor.withValues(alpha: 0.1)
          : (isDark ? const Color(0xFF111726) : const Color(0xFFFFFFFF)),
      borderColor: statusColor.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLoaded ? Icons.check_circle_outline_rounded : Icons.memory_rounded,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLoaded ? 'LOCAL ENGINE READY' : 'NO MODEL LOADED',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    AppStatusBadge(
                      label: isLoaded ? 'ONLINE' : 'OFFLINE',
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isLoaded ? 'Active Model: $modelName' : 'Select an installed model to enable inference.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, ThemeData theme, {bool isAccent = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            SelectableText(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isAccent ? const Color(0xFF10B981) : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
