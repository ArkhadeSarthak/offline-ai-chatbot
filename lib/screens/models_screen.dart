import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_model.dart';
import '../theme/app_theme.dart';
import '../services/model_app_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = Provider.of<ModelAppState>(context);
    final recommendedModel = widget.models.firstWhere(
      (m) => m.isRecommended,
      orElse: () => widget.models.first,
    );
    final isRecommendedPaused = recommendedModel.isDownloading &&
        state.downloadingModel?.id == recommendedModel.id &&
        state.isPaused;

    final regularModels = widget.models.where((m) => !m.isRecommended).toList();

    regularModels.sort((a, b) {
      final aVal = double.tryParse(a.size.split(' ').first) ?? 0.0;
      final bVal = double.tryParse(b.size.split(' ').first) ?? 0.0;
      return _sortAscending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Recommended Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended for Mobile',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.08),
                border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'OPTIMIZED',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recommended Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.15)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'STATE OF THE ART INFERENCE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                recommendedModel.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                recommendedModel.description,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTagChip(recommendedModel.size, theme),
                  _buildTagChip(recommendedModel.ramRequired, theme),
                  _buildTagChip(recommendedModel.quantization, theme),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: recommendedModel.isDownloaded
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        label: Text('Ready to Use',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.05),
                          side:
                              BorderSide(color: Colors.green.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : recommendedModel.isDownloading
                        ? Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isRecommendedPaused
                                  ? Colors.amber.withOpacity(0.08)
                                  : theme.colorScheme.primary.withOpacity(0.08),
                              border: Border.all(
                                  color: isRecommendedPaused
                                      ? Colors.amber.withOpacity(0.2)
                                      : theme.colorScheme.primary
                                          .withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isRecommendedPaused) ...[
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primary),
                                  ),
                                  const SizedBox(width: 10),
                                ] else ...[
                                  const Icon(Icons.pause, color: Colors.amber, size: 14),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  isRecommendedPaused ? 'Paused...' : 'Downloading...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isRecommendedPaused ? Colors.amber : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () =>
                                widget.onStartDownload(recommendedModel.id),
                            icon: const Icon(Icons.download, size: 18),
                            label: Text('Download Model',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // All Models Title & Sorting
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Models',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            InkWell(
              onTap: () => setState(() => _sortAscending = !_sortAscending),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _sortAscending ? 'SIZE: ASCENDING' : 'SIZE: DESCENDING',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Models List
        ...regularModels.map((model) {
          final isModelPaused = model.isDownloading &&
              state.downloadingModel?.id == model.id &&
              state.isPaused;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          border: Border.all(
                              color: theme.colorScheme.primary
                                  .withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getModelIcon(model.id),
                            color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              model.isDownloading
                                  ? (isModelPaused
                                      ? 'Paused... ${(model.downloadProgress * 1.8).toStringAsFixed(1)} GB / ${model.size}'
                                      : 'Downloading... ${(model.downloadProgress * 1.8).toStringAsFixed(1)} GB / ${model.size}')
                                  : '${model.size} • ${model.ramRequired} Required',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: model.isDownloading
                                    ? (isModelPaused ? Colors.amber : theme.colorScheme.primary)
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildListActionIcon(model, theme, isModelPaused),
                    ],
                  ),
                  if (model.isDownloading) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: model.downloadProgress,
                        minHeight: 4,
                        backgroundColor:
                            theme.colorScheme.outline.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isModelPaused ? Colors.amber : theme.colorScheme.primary),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTagChip(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.06),
        border:
            Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildListActionIcon(AIModel model, ThemeData theme, bool isPaused) {
    if (model.isDownloaded) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.green, size: 16),
      );
    } else if (model.isDownloading) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPaused ? Colors.amber.withOpacity(0.08) : theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isPaused ? Colors.amber.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Center(
          child: isPaused
              ? const Icon(Icons.pause, color: Colors.amber, size: 16)
              : const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary),
                ),
        ),
      );
    } else {
      return InkWell(
        onTap: () => widget.onStartDownload(model.id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
          ),
          child: Icon(Icons.download_rounded,
              color: theme.colorScheme.onSurface, size: 16),
        ),
      );
    }
  }
}
