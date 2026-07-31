import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_model.dart';
import '../services/model_app_state.dart';

class DownloadsScreen extends StatefulWidget {
  final AIModel? downloadingModel;
  final VoidCallback onCancelDownload;
  final VoidCallback onCompleteDownload;

  const DownloadsScreen({
    Key? key,
    this.downloadingModel,
    required this.onCancelDownload,
    required this.onCompleteDownload,
  }) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelAppState = Provider.of<ModelAppState>(context);
    final model = modelAppState.downloadingModel;
    final double progress = modelAppState.downloadProgress * 100;
    final List<String> logs = modelAppState.downloadLogs.isEmpty
        ? ["[DOWNLOAD] Waiting for download stream...", "[INFO] Storage verified."]
        : modelAppState.downloadLogs;

    final double speed = modelAppState.downloadSpeed;
    final int timeRemaining = modelAppState.timeRemaining;
    final bool isPaused = modelAppState.isPaused;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if (model != null) ...[
                      // Active Download Label
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.08),
                            border: Border.all(
                                color: theme.colorScheme.secondary
                                    .withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'DOWNLOADING MODEL',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        model.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quantized ${model.quantization} • ${model.size}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Radial Circle Progress Graphic
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(170, 170),
                              painter: _CircleProgressPainter(
                                progress: progress,
                                primaryColor: theme.colorScheme.primary,
                                accentColor: theme.colorScheme.secondary,
                                outlineColor: theme.colorScheme.outline,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${progress.floor()}%',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isPaused
                                            ? Colors.amber
                                            : theme.colorScheme.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPaused ? 'PAUSED' : 'ACTIVE',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Twin Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.15)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'SPEED',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.4)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPaused
                                        ? '0.0 MB/s'
                                        : '${speed.toStringAsFixed(1)} MB/s',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.15)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'ESTIMATED',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.4)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPaused
                                        ? '--'
                                        : _formatTime(timeRemaining),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 5,
                          backgroundColor:
                              theme.colorScheme.outline.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SHARD ${math.min(12, (progress / 8.3).floor() + 1)}/12',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4)),
                          ),
                          Text(
                            'CRC VALIDATION ACTIVE',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Controls Bar
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (isPaused) {
                                    modelAppState.resumeDownload();
                                  } else {
                                    modelAppState.pauseDownload();
                                  }
                                },
                                icon: Icon(
                                    isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    size: 18),
                                label: Text(
                                    isPaused
                                        ? 'Resume Download'
                                        : 'Pause Download',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface,
                                  foregroundColor: theme.colorScheme.onSurface,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: theme.colorScheme.outline
                                            .withOpacity(0.15)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 48,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: widget.onCancelDownload,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(
                                    color: Colors.redAccent.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Telemetry terminal console
                      Container(
                        height: 140,
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF040A18),
                          border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.terminal_rounded,
                                    size: 13, color: theme.colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'TELEMETRY MONITOR',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                _TelemetryPulsar(isPaused: isPaused || model == null),
                              ],
                            ),
                            const Divider(color: Color(0xFF131F35), height: 16),
                            Expanded(
                              child: ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  Color logColor =
                                      theme.colorScheme.onSurface.withOpacity(0.5);
                                  if (log.startsWith('[DOWNLOAD]')) {
                                    logColor = theme.colorScheme.secondary;
                                  }
                                  if (log.startsWith('[MEMORY]')) {
                                    logColor = theme.colorScheme.primary;
                                  }
                                  if (log.startsWith('[INFO]') ||
                                      log.startsWith('[ENGINE]')) {
                                    logColor = Colors.cyan;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('>',
                                            style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10,
                                                color: Colors.white.withOpacity(0.15))),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            log,
                                            style: GoogleFonts.jetBrainsMono(
                                                fontSize: 10.5, color: logColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Empty state
                      const SizedBox(height: 80),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withOpacity(0.06),
                          border: Border.all(
                              color:
                                  theme.colorScheme.outline.withOpacity(0.12)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_download_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Active Downloads',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Go to the Models tab to browse offline neural networks and download them directly to your device.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                              height: 1.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryPulsar extends StatefulWidget {
  final bool isPaused;
  const _TelemetryPulsar({Key? key, required this.isPaused}) : super(key: key);

  @override
  State<_TelemetryPulsar> createState() => _TelemetryPulsarState();
}

class _TelemetryPulsarState extends State<_TelemetryPulsar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPaused) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final Color outlineColor;

  _CircleProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // 1. Draw outer thin background track
    final bgPaint = Paint()
      ..color = outlineColor.withOpacity(0.08)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Draw outer active progress arc
    final activePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final sweepAngle = (progress / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );

    // 3. Draw inner tech dash-dot circle
    final innerRadius = radius - 12;
    final dashPaint = Paint()
      ..color = accentColor.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const int dashCount = 36;
    final double dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        final double start = i * dashAngle - (math.pi / 2);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          start,
          dashAngle * 0.7,
          false,
          dashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}
