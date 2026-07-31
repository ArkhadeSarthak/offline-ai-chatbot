import 'dart:io';
import 'package:flutter/foundation.dart';

class GgufValidationResult {
  final bool isValid;
  final String? error;
  final int? version;
  final int? tensorCount;
  final int? metadataCount;
  final int fileSize;

  GgufValidationResult({
    required this.isValid,
    this.error,
    this.version,
    this.tensorCount,
    this.metadataCount,
    required this.fileSize,
  });

  @override
  String toString() {
    if (isValid) {
      return "GgufValidationResult(Valid, Version: $version, Tensors: $tensorCount, Metadata: $metadataCount, Size: $fileSize bytes)";
    }
    return "GgufValidationResult(Invalid: $error, Size: $fileSize bytes)";
  }
}

class GgufValidator {
  static const List<int> _ggufMagic = [0x47, 0x47, 0x55, 0x46]; // ASCII "GGUF"

  static Future<GgufValidationResult> validateFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return GgufValidationResult(
        isValid: false,
        error: "File does not exist at path: $filePath",
        fileSize: 0,
      );
    }

    final length = await file.length();
    // GGUF files must be at least 24 bytes (header size)
    if (length < 24) {
      return GgufValidationResult(
        isValid: false,
        error: "File is too small to be a valid GGUF model ($length bytes)",
        fileSize: length,
      );
    }

    RandomAccessFile? raf;
    try {
      raf = await file.open(mode: FileMode.read);
      final headerBytes = await raf.read(24);
      if (headerBytes.length < 24) {
        return GgufValidationResult(
          isValid: false,
          error: "Could not read complete 24-byte GGUF header",
          fileSize: length,
        );
      }

      // Check magic number (first 4 bytes)
      for (int i = 0; i < 4; i++) {
        if (headerBytes[i] != _ggufMagic[i]) {
          final sampleStr = String.fromCharCodes(headerBytes.take(16)).replaceAll(RegExp(r'[^\x20-\x7E]'), '?');
          return GgufValidationResult(
            isValid: false,
            error: "Invalid magic bytes. Expected 'GGUF', found header preview: '$sampleStr'",
            fileSize: length,
          );
        }
      }

      final ByteData byteData = ByteData.sublistView(Uint8List.fromList(headerBytes));
      final int version = byteData.getUint32(4, Endian.little);
      if (version < 1 || version > 10) {
        return GgufValidationResult(
          isValid: false,
          error: "Unsupported GGUF version: $version",
          fileSize: length,
        );
      }

      final int tensorCount = byteData.getUint64(8, Endian.little);
      final int metadataCount = byteData.getUint64(16, Endian.little);

      debugPrint("[LocalMind] GGUF Validation Passed: version=$version, tensors=$tensorCount, metadata_entries=$metadataCount, fileSize=${(length / (1024 * 1024)).toStringAsFixed(2)} MB");

      return GgufValidationResult(
        isValid: true,
        version: version,
        tensorCount: tensorCount,
        metadataCount: metadataCount,
        fileSize: length,
      );
    } catch (e) {
      return GgufValidationResult(
        isValid: false,
        error: "Exception reading GGUF header: $e",
        fileSize: length,
      );
    } finally {
      if (raf != null) {
        try {
          await raf.close();
        } catch (_) {}
      }
    }
  }
}
