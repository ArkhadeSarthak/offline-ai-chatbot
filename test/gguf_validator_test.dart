import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_mind/services/gguf_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GgufValidator Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gguf_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('validates valid GGUF header correctly', () async {
      final file = File('${tempDir.path}/valid_model.gguf');
      final bytes = Uint8List(32);
      final byteData = ByteData.sublistView(bytes);
      
      // Magic "GGUF" = 0x47, 0x47, 0x55, 0x46
      bytes[0] = 0x47;
      bytes[1] = 0x47;
      bytes[2] = 0x55;
      bytes[3] = 0x46;
      
      // Version = 3 (little endian)
      byteData.setUint32(4, 3, Endian.little);
      // Tensor count = 200
      byteData.setUint64(8, 200, Endian.little);
      // Metadata count = 50
      byteData.setUint64(16, 50, Endian.little);

      await file.writeAsBytes(bytes);

      final result = await GgufValidator.validateFile(file.path);
      expect(result.isValid, isTrue);
      expect(result.version, equals(3));
      expect(result.tensorCount, equals(200));
      expect(result.metadataCount, equals(50));
      expect(result.error, isNull);
    });

    test('rejects non-existent file', () async {
      final result = await GgufValidator.validateFile('${tempDir.path}/non_existent.gguf');
      expect(result.isValid, isFalse);
      expect(result.error, contains('File does not exist'));
    });

    test('rejects truncated / small file', () async {
      final file = File('${tempDir.path}/small.gguf');
      await file.writeAsBytes([0x47, 0x47, 0x55, 0x46]);

      final result = await GgufValidator.validateFile(file.path);
      expect(result.isValid, isFalse);
      expect(result.error, contains('too small'));
    });

    test('rejects file with invalid magic bytes (e.g. HTML error page)', () async {
      final file = File('${tempDir.path}/html_response.gguf');
      const htmlContent = '<html><body>404 Not Found</body></html>';
      await file.writeAsString(htmlContent);

      final result = await GgufValidator.validateFile(file.path);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Invalid magic bytes'));
    });
  });
}
