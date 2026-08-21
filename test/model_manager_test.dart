import 'package:flutter_test/flutter_test.dart';
import 'package:local_mind/services/model_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModelManager Registry Tests', () {
    late ModelManager modelManager;

    setUp(() {
      modelManager = ModelManager();
    });

    test('verifies standard model registry contains Gemma 3 1B and Qwen 2.5 3B', () {
      final models = modelManager.availableModels;
      expect(models.isNotEmpty, isTrue);

      final gemma = models.firstWhere((m) => m.id == 'gemma3_1b');
      expect(gemma.name, contains('Gemma 3 1B'));
      expect(gemma.fileName, equals('gemma-3-1b-it-Q4_K_M.gguf'));
      expect(gemma.isRecommended, isTrue);
      expect(gemma.minimumRamGB, lessThanOrEqualTo(2.5));

      final qwen3b = models.firstWhere((m) => m.id == 'qwen2.5_3b');
      expect(qwen3b.name, contains('Qwen 2.5 3B'));
      expect(qwen3b.fileName, equals('qwen2.5-3b-instruct-q4_k_m.gguf'));
      expect(qwen3b.quantization, equals('Q4_K_M'));
    });

    test('validates storage calculation logic', () async {
      final hasSpace = await modelManager.hasSufficientStorage(1024 * 1024);
      expect(hasSpace, isTrue);
    });
  });
}
