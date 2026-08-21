import 'package:flutter_test/flutter_test.dart';
import 'package:local_mind/services/device_capability_service.dart';
import 'package:local_mind/services/model_memory_estimator.dart';
import 'package:local_mind/services/settings_service.dart';
import 'package:local_mind/models/ai_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceCapabilityService Tests', () {
    test('analyzeCapability returns valid profile', () async {
      final profile = await DeviceCapabilityService.analyzeCapability();
      expect(profile.totalRamGB, greaterThan(0));
      expect(profile.availableRamGB, greaterThan(0));
      expect(profile.defaultContextLength, greaterThanOrEqualTo(1024));
      expect(profile.defaultCpuThreads, greaterThanOrEqualTo(1));
    });

    test('getAdaptiveSettings enforces safe mode parameters when requested', () {
      final profile = DeviceProfile(
        tier: DeviceTier.low,
        totalRamGB: 4.0,
        availableRamGB: 1.8,
        defaultContextLength: 1024,
        defaultBatchSize: 256,
        defaultCpuThreads: 2,
        isSafeModeRecommended: true,
      );

      final settings = DeviceCapabilityService.getAdaptiveSettings(profile, forceSafeMode: true);
      expect(settings.contextLength, equals(1024));
      expect(settings.cpuThreads, equals(2));
      expect(settings.maxTokens, equals(512));
    });
  });

  group('ModelMemoryEstimator Tests', () {
    final testModel = AIModel(
      id: 'test_model',
      name: 'Test Model 3B',
      size: '2.2 GB',
      fileSizeBytes: 2200000000, // ~2.05 GB
      ramRequired: '4 GB',
      minimumRamGB: 3.5,
      recommendedRamGB: 6.0,
      quantization: 'Q4_K_M',
      description: 'Test model for memory estimation',
      downloadUrl: 'https://example.com/model.gguf',
      fileName: 'model.gguf',
      chatTemplate: 'chatml',
    );

    test('evaluates safe status when memory is abundant', () {
      final profile = DeviceProfile(
        tier: DeviceTier.high,
        totalRamGB: 12.0,
        availableRamGB: 8.0,
        defaultContextLength: 2048,
        defaultBatchSize: 512,
        defaultCpuThreads: 4,
        isSafeModeRecommended: false,
      );

      final settings = InferenceSettings(contextLength: 2048);
      final eval = ModelMemoryEstimator.evaluate(
        model: testModel,
        deviceProfile: profile,
        settings: settings,
      );

      expect(eval.status, equals(MemorySafetyStatus.safe));
      expect(eval.isSafe, isTrue);
      expect(eval.isUnsafe, isFalse);
    });

    test('evaluates unsafe status when memory is insufficient', () {
      final profile = DeviceProfile(
        tier: DeviceTier.low,
        totalRamGB: 3.0,
        availableRamGB: 1.2,
        defaultContextLength: 2048,
        defaultBatchSize: 256,
        defaultCpuThreads: 2,
        isSafeModeRecommended: true,
      );

      final settings = InferenceSettings(contextLength: 2048);
      final eval = ModelMemoryEstimator.evaluate(
        model: testModel,
        deviceProfile: profile,
        settings: settings,
      );

      expect(eval.status, equals(MemorySafetyStatus.unsafe));
      expect(eval.isUnsafe, isTrue);
      expect(eval.message, contains('Loading it may cause Android to close LocalMind'));
    });
  });
}
