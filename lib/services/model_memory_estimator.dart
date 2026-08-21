import 'package:flutter/foundation.dart';
import '../models/ai_model.dart';
import 'device_capability_service.dart';
import 'settings_service.dart';

enum MemorySafetyStatus {
  safe,
  caution,
  unsafe,
}

class ModelMemoryEvaluation {
  final MemorySafetyStatus status;
  final double estimatedRequiredRamGB;
  final double availableRamGB;
  final String message;
  final InferenceSettings recommendedSafeSettings;

  ModelMemoryEvaluation({
    required this.status,
    required this.estimatedRequiredRamGB,
    required this.availableRamGB,
    required this.message,
    required this.recommendedSafeSettings,
  });

  bool get isSafe => status == MemorySafetyStatus.safe;
  bool get isCaution => status == MemorySafetyStatus.caution;
  bool get isUnsafe => status == MemorySafetyStatus.unsafe;
}

class ModelMemoryEstimator {
  static ModelMemoryEvaluation evaluate({
    required AIModel model,
    required DeviceProfile deviceProfile,
    required InferenceSettings settings,
  }) {
    // 1. Model file size in GB
    final double modelSizeGB = model.fileSizeBytes / (1024.0 * 1024.0 * 1024.0);

    // 2. KV Cache estimation: contextLength * 1024 * 4 bytes per token
    final double kvCacheGB = (settings.contextLength * 1024 * 4) / (1024.0 * 1024.0 * 1024.0);

    // 3. Compute buffer & OS app headroom
    const double computeBufferGB = 0.20;
    const double systemHeadroomGB = 0.50;

    final double totalRequiredGB = modelSizeGB + kvCacheGB + computeBufferGB + systemHeadroomGB;
    final double availableRamGB = deviceProfile.availableRamGB;

    MemorySafetyStatus status;
    String message;

    if (totalRequiredGB <= availableRamGB * 0.85) {
      status = MemorySafetyStatus.safe;
      message = "Your device has sufficient memory (~${availableRamGB.toStringAsFixed(1)} GB free) for ${model.name}.";
    } else if (totalRequiredGB <= availableRamGB + 0.3) {
      status = MemorySafetyStatus.caution;
      message = "Memory is tight (~${availableRamGB.toStringAsFixed(1)} GB free). ${model.name} will run, but performance may be constrained.";
    } else {
      status = MemorySafetyStatus.unsafe;
      message = "This model requires ~${totalRequiredGB.toStringAsFixed(1)} GB memory, but only ~${availableRamGB.toStringAsFixed(1)} GB is free on your device. Loading it may cause Android to close LocalMind.";
    }

    final safeSettings = InferenceSettings(
      temperature: settings.temperature,
      topP: settings.topP,
      topK: settings.topK,
      repeatPenalty: settings.repeatPenalty,
      contextLength: 1024,
      cpuThreads: 2,
      maxTokens: 512,
    );

    debugPrint("[ModelMemoryEstimator] Model=${model.name}, Req=${totalRequiredGB.toStringAsFixed(2)}GB, Avail=${availableRamGB.toStringAsFixed(2)}GB -> Status=${status.name}");

    return ModelMemoryEvaluation(
      status: status,
      estimatedRequiredRamGB: totalRequiredGB,
      availableRamGB: availableRamGB,
      message: message,
      recommendedSafeSettings: safeSettings,
    );
  }
}
