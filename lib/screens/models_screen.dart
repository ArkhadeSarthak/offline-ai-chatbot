import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_model.dart';
import '../services/model_app_state.dart';
import '../widgets/app_components.dart';
import '../widgets/app_feedback_service.dart';

class ModelsScreen extends StatefulWidget {
  final List<AIModel> models;
  final Function(String) onStartDownload;

  const ModelsScreen({
    Key? key,
    required this.models,
    required this.onStartDownload,
  }) : super(key: key);

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  bool _sortAscending = true;

  IconData _getModelIcon(String modelId) {
    if (modelId.startsWith('qwen')) {
      return Icons.hexagon_outlined;
    } else if (modelId.startsWith('llama')) {
      return Icons.radio_button_checked_rounded;
    } else if (modelId.startsWith('phi')) {
      return Icons.lightbulb_outline_rounded;
    } else if (modelId.startsWith('smollm')) {
      return Icons.bubble_chart_outlined;
    } else {
      return Icons.auto_awesome_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 MB";
    final double mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(1)} MB";
  }

  String _formatTimeRemaining(int seconds) {
    if (seconds <= 0) return "--:--";
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins >= 60) {
      final hrs = mins ~/ 60;
      final remMins = mins % 60;
      return "${hrs}h ${remMins}m";
    }
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _handleDownloadClick(AIModel model) async {
    final sizeGB = model.fileSizeBytes / (1024.0 * 1024.0 * 1024.0);
    final confirmed = await AppFeedbackService.showDownloadConfirmation(
      context,
      modelName: model.name,
      fileSizeGB: sizeGB,
      freeStorageGB: 16.0,
    );

    if (confirmed) {
      widget.onStartDownload(model.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<ModelAppState>(context);

    final installedList = widget.models.where((m) => m.installed || m.isDownloaded).toList();
    final availableList = widget.models.where((m) => !m.installed && !m.isDownloaded).toList();

    availableList.sort((a, b) {
      final aVal = double.tryParse(a.size.split(' ').first) ?? 0.0;
      final bVal = double.tryParse(b.size.split(' ').first) ?? 0.0;
      return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });

    final activeModel = widget.models.firstWhere(
      (m) => m.id == state.selectedModelId,
      orElse: () => widget.models.first,
    );
    final isModelLoaded = state.llmService.isModelLoaded && activeModel.installed;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Subtitle Branding Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Private AI Engine',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Runs 100% offline on local device RAM & CPU',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ACTIVE MODEL STATUS CARD
        const AppSectionHeader(title: 'Active Engine'),
        AppCard(
          backgroundColor: isModelLoaded
              ? (isDark ? const Color(0xFF0F2027) : const Color(0xFFE0F2FE))
              : (isDark ? const Color(0xFF111726) : const Color(0xFFFFFFFF)),
          borderColor: isModelLoaded
              ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isModelLoaded
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getModelIcon(activeModel.id),
                  color: isModelLoaded ? const Color(0xFF00E5FF) : theme.textTheme.bodyMedium?.color,
                  size: 26,
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
                            isModelLoaded ? activeModel.name : 'No Model Loaded',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isModelLoaded)
                          const AppStatusBadge(
                            label: 'RUNNING',
                            color: Color(0xFF10B981),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isModelLoaded
                          ? '${activeModel.size} • ${activeModel.quantization} • ${activeModel.chatTemplate}'
                          : 'Select an installed model below to load native inference context.',
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
        ),

        const SizedBox(height: 20),

        // INSTALLED MODELS SECTION
        if (installedList.isNotEmpty) ...[
          AppSectionHeader(title: 'Installed Models (${installedList.length})'),
          ...installedList.map((model) => _buildModelItemCard(context, model, state, isInstalled: true)),
          const SizedBox(height: 20),
        ],

        // AVAILABLE TO DOWNLOAD SECTION
        AppSectionHeader(
          title: 'Available Models (${availableList.length})',
          trailing: InkWell(
            onTap: () => setState(() => _sortAscending = !_sortAscending),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 13,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Size',
                    style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (availableList.isEmpty)
          const AppEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'All Models Downloaded',
            description: 'You have downloaded all models available in the LocalMind library.',
          )
        else
          ...availableList.map((model) => _buildModelItemCard(context, model, state, isInstalled: false)),
      ],
    );
  }

  Widget _buildModelItemCard(BuildContext context, AIModel model, ModelAppState state, {required bool isInstalled}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = state.selectedModelId == model.id;
    final isDownloading = model.isDownloading || (state.downloadingModel?.id == model.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        backgroundColor: isSelected
            ? (isDark ? const Color(0xFF141E33) : const Color(0xFFF0F9FF))
            : (isDark ? const Color(0xFF111726) : const Color(0xFFFFFFFF)),
        borderColor: isDownloading
            ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
            : isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outline.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getModelIcon(model.id),
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (model.isRecommended)
                            const AppStatusBadge(
                              label: 'RECOMMENDED',
                              color: Color(0xFF00E5FF),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 12),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildMetaChip(context, Icons.storage_outlined, model.size),
                _buildMetaChip(context, Icons.memory_outlined, '${model.minimumRamGB.toStringAsFixed(1)} GB RAM'),
                _buildMetaChip(context, Icons.compress_rounded, model.quantization),
              ],
            ),

            // ACTIVE INLINE DOWNLOAD CARD SECTION
            if (isDownloading) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          model.isVerifying
                              ? 'Verifying GGUF header...'
                              : state.isPaused
                                  ? 'Paused'
                                  : 'Downloading GGUF shard...',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: model.isVerifying
                                ? const Color(0xFF10B981)
                                : state.isPaused
                                    ? Colors.orangeAccent
                                    : theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${(state.downloadProgress * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: model.isVerifying ? null : state.downloadProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          model.isVerifying ? const Color(0xFF10B981) : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_formatBytes(state.downloadedBytes)} / ${_formatBytes(state.totalBytes)}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: theme.textTheme.bodyMedium?.color),
                        ),
                        Text(
                          '${state.downloadSpeed.toStringAsFixed(1)} MB/s • ${_formatTimeRemaining(state.timeRemaining)}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!model.isVerifying) ...[
                          if (state.isPaused)
                            AppButton(
                              label: 'Resume',
                              icon: Icons.play_arrow_rounded,
                              style: AppButtonStyle.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              onPressed: () => state.resumeDownload(),
                            )
                          else
                            AppButton(
                              label: 'Pause',
                              icon: Icons.pause_rounded,
                              style: AppButtonStyle.secondary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              onPressed: () => state.pauseDownload(),
                            ),
                          const SizedBox(width: 8),
                        ],
                        AppButton(
                          label: 'Cancel',
                          icon: Icons.close_rounded,
                          style: AppButtonStyle.outline,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          onPressed: () => state.cancelDownload(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isInstalled)
                  AppStatusBadge(
                    label: isSelected ? 'ACTIVE MODEL' : 'INSTALLED',
                    color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF10B981),
                  )
                else if (isDownloading)
                  const AppStatusBadge(
                    label: 'DOWNLOADING...',
                    color: Color(0xFFF59E0B),
                  )
                else
                  Text(
                    'Requires ${model.size}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                  ),

                if (!isDownloading)
                  Row(
                    children: [
                      if (isInstalled) ...[
                        if (!isSelected)
                          AppButton(
                            label: state.isModelLoading && state.selectedModelId == model.id ? 'Loading...' : 'Load',
                            icon: Icons.play_arrow_rounded,
                            isLoading: state.isModelLoading && state.selectedModelId == model.id,
                            style: AppButtonStyle.outline,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onPressed: state.isModelLoading
                                ? null
                                : () async {
                                    final eval = await state.evaluateModelMemory(model);
                                    if (!context.mounted) return;
                                    if (eval.isUnsafe || eval.isCaution) {
                                      final action = await AppFeedbackService.showLowMemoryWarning(
                                        context,
                                        modelName: model.name,
                                        message: eval.message,
                                      );
                                      if (action == 'cancel') return;
                                      final useSafeMode = (action == 'safe_mode');
                                      await state.selectModel(model.id, forceSafeMode: useSafeMode);
                                      if (context.mounted) {
                                        if (state.modelLoadingError != null) {
                                          AppFeedbackService.showToast(context, state.modelLoadingError!, isError: true);
                                        } else {
                                          AppFeedbackService.showToast(context, '${model.name} loaded successfully!');
                                        }
                                      }
                                      return;
                                    }
                                    await state.selectModel(model.id);
                                    if (context.mounted) {
                                      if (state.modelLoadingError != null) {
                                        AppFeedbackService.showToast(context, state.modelLoadingError!, isError: true);
                                      } else {
                                        AppFeedbackService.showToast(context, '${model.name} loaded successfully!');
                                      }
                                    }
                                  },
                          )
                        else
                          AppButton(
                            label: 'Loaded',
                            icon: Icons.check_circle_rounded,
                            style: AppButtonStyle.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            onPressed: () {},
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Model',
                          onPressed: () async {
                            final sizeGB = model.fileSizeBytes / (1024.0 * 1024.0 * 1024.0);
                            final confirm = await AppFeedbackService.showDeleteConfirmation(
                              context,
                              modelName: model.name,
                              fileSizeGB: sizeGB,
                            );
                            if (confirm) {
                              await state.deleteModel(model.id);
                            }
                          },
                        ),
                      ] else ...[
                        AppButton(
                          label: 'Download',
                          icon: Icons.download_rounded,
                          style: AppButtonStyle.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          onPressed: () => _handleDownloadClick(model),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
