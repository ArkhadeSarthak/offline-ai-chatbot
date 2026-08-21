import 'package:flutter/foundation.dart';
import 'device_info_helper.dart';
import 'settings_service.dart';

enum DeviceTier {
  low,
  medium,
  high,
}

class DeviceProfile {
  final DeviceTier tier;
  final double totalRamGB;
  final double availableRamGB;
  final int defaultContextLength;
  final int defaultBatchSize;
  final int defaultCpuThreads;
  final bool isSafeModeRecommended;

  DeviceProfile({
    required this.tier,
    required this.totalRamGB,
    required this.availableRamGB,
    required this.defaultContextLength,
    required this.defaultBatchSize,
    required this.defaultCpuThreads,
    required this.isSafeModeRecommended,
  });

  String get tierName {
    switch (tier) {
      case DeviceTier.low:
        return 'Low-Memory Device';
      case DeviceTier.medium:
        return 'Mid-Range Device';
      case DeviceTier.high:
        return 'High-Performance Device';
    }
  }
}

class DeviceCapabilityService {
  static Future<DeviceProfile> analyzeCapability() async {
    try {
      final specs = await DeviceInfoHelper.getDeviceSpecs();
      final totalRam = specs.totalRamGB;
      final freeRam = (specs.totalRamGB - specs.usedRamGB).clamp(0.1, specs.totalRamGB);

      DeviceTier tier;
      int nCtx;
      int nBatch;
      int nThreads;
      bool safeMode;

      if (freeRam < 2.2 || totalRam <= 4.0) {
        tier = DeviceTier.low;
        nCtx = 1024;
        nBatch = 256;
        nThreads = 2;
        safeMode = true;
      } else if (freeRam < 4.2 || totalRam <= 8.0) {
        tier = DeviceTier.medium;
        nCtx = 2048;
        nBatch = 512;
        nThreads = 3;
        safeMode = false;
      } else {
        tier = DeviceTier.high;
        nCtx = 4096;
        nBatch = 512;
        nThreads = 4;
        safeMode = false;
      }

      debugPrint("[DeviceCapabilityService] Tier=${tier.name}, TotalRAM=${totalRam.toStringAsFixed(1)}GB, FreeRAM=${freeRam.toStringAsFixed(1)}GB, nCtx=$nCtx, nThreads=$nThreads");

      return DeviceProfile(
        tier: tier,
        totalRamGB: totalRam,
        availableRamGB: freeRam,
        defaultContextLength: nCtx,
        defaultBatchSize: nBatch,
        defaultCpuThreads: nThreads,
        isSafeModeRecommended: safeMode,
      );
    } catch (e) {
      debugPrint("[DeviceCapabilityService] Error analyzing capability: $e");
      return DeviceProfile(
        tier: DeviceTier.low,
        totalRamGB: 4.0,
        availableRamGB: 2.0,
        defaultContextLength: 1024,
        defaultBatchSize: 256,
        defaultCpuThreads: 2,
        isSafeModeRecommended: true,
      );
    }
  }

  static InferenceSettings getAdaptiveSettings(DeviceProfile profile, {bool forceSafeMode = false}) {
    if (forceSafeMode || profile.isSafeModeRecommended) {
      return InferenceSettings(
        temperature: 0.70,
        topP: 0.90,
        topK: 40,
        repeatPenalty: 1.10,
        contextLength: 1024,
        cpuThreads: 2,
        maxTokens: 512,
      );
    }

    return InferenceSettings(
      temperature: 0.70,
      topP: 0.90,
      topK: 40,
      repeatPenalty: 1.10,
      contextLength: profile.defaultContextLength,
      cpuThreads: profile.defaultCpuThreads,
      maxTokens: 1024,
    );
  }
}
