import 'dart:convert';

/// Representation of a parsed block of content in an AI response.
abstract class ResponseBlock {}

/// A standard paragraph of text or header.
class ParagraphBlock extends ResponseBlock {
  final String text;
  final bool isHeader;

  ParagraphBlock(this.text, {this.isHeader = false});
}

/// An unordered bullet list block.
class BulletListBlock extends ResponseBlock {
  final List<String> items;

  BulletListBlock(this.items);
}

/// An ordered numbered list block.
class NumberedListBlock extends ResponseBlock {
  final List<String> items;

  NumberedListBlock(this.items);
}

/// A code block with optional programming language and raw content.
class CodeBlock extends ResponseBlock {
  final String language;
  final String code;

  CodeBlock({required this.language, required this.code});
}

/// An example section callout block.
class ExampleBlock extends ResponseBlock {
  final String title;
  final List<String> lines;

  ExampleBlock({this.title = 'Example', required this.lines});
}

/// An error or warning block for invalid/failed responses.
class ErrorBlock extends ResponseBlock {
  final String message;

  ErrorBlock(this.message);
}

/// Sanitizes raw AI model output and strips unwanted formatting/tokens/JSON wrappers.
class ResponseSanitizer {
  static String sanitize(String rawText, {String? status}) {
    if (status == 'error') {
      if (rawText.trim().isEmpty) {
        return "An error occurred while generating the response. Please try again.";
      }
      return rawText.trim();
    }

    if (rawText.trim().isEmpty) {
      return "No content received.";
    }

    String cleaned = rawText;

    // Extract message if output is raw JSON payload
    final trimmed = cleaned.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          if (decoded.containsKey('error')) {
            return "API Error: ${decoded['error']}";
          } else if (decoded.containsKey('message')) {
            cleaned = decoded['message'].toString();
          } else if (decoded.containsKey('response')) {
            cleaned = decoded['response'].toString();
          } else if (decoded.containsKey('content')) {
            cleaned = decoded['content'].toString();
          } else if (decoded.containsKey('text')) {
            cleaned = decoded['text'].toString();
          }
        }
      } catch (_) {
        // Not valid JSON object, keep original
      }
    }

    // Strip leftover prompt special tokens
    final stopTokens = [
      '<end_of_turn>',
      '<|im_end|>',
      '<|eot_id|>',
      '<|end|>',
      '<|endoftext|>',
      '<eos>',
      '<|begin_of_text|>',
      '<|start_of_turn|>',
      '<|im_start|>',
      '<|system|>',
      '<|user|>',
      '<|assistant|>',
      '[INST]',
      '[/INST]',
    ];

    for (final token in stopTokens) {
      cleaned = cleaned.replaceAll(token, '');
    }

    // Normalize excessive newlines (max 2 consecutive newlines)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return cleaned.trim();
  }
}

/// Parses sanitized response text into structured blocks.
class ResponseBlockParser {
  static List<ResponseBlock> parse(String text, {String? status}) {
    final sanitized = ResponseSanitizer.sanitize(text, status: status);

    if (status == 'error') {
      return [ErrorBlock(sanitized)];
    }

    if (sanitized.isEmpty) {
      return [ParagraphBlock('')];
    }

    final blocks = <ResponseBlock>[];

    // 1. Separate code blocks from normal text
    final codeBlockRegex = RegExp(r'```([a-zA-Z0-9_+\-]*)\n?([\s\S]*?)(?:```|$)');
    int lastEnd = 0;

    for (final match in codeBlockRegex.allMatches(sanitized)) {
      if (match.start > lastEnd) {
        final nonCodeText = sanitized.substring(lastEnd, match.start);
        blocks.addAll(_parseNonCodeText(nonCodeText));
      }

      final lang = match.group(1)?.trim() ?? '';
      String codeContent = match.group(2) ?? '';
      // Trim ending newline if present
      if (codeContent.endsWith('\n')) {
        codeContent = codeContent.substring(0, codeContent.length - 1);
      }

      if (codeContent.isNotEmpty || lang.isNotEmpty) {
        blocks.add(CodeBlock(
          language: lang.isEmpty ? 'CODE' : lang.toUpperCase(),
          code: codeContent,
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < sanitized.length) {
      final remainingText = sanitized.substring(lastEnd);
      blocks.addAll(_parseNonCodeText(remainingText));
    }

    return blocks.isEmpty ? [ParagraphBlock(sanitized)] : blocks;
  }

  static List<ResponseBlock> _parseNonCodeText(String text) {
    if (text.trim().isEmpty) return [];

    final blocks = <ResponseBlock>[];
    final lines = text.split('\n');

    List<String> currentBulletItems = [];
    List<String> currentNumberedItems = [];
    List<String> currentParagraphLines = [];
    List<String> currentExampleLines = [];
    bool inExampleSection = false;

    void flushParagraph() {
      if (currentParagraphLines.isNotEmpty) {
        final pText = currentParagraphLines.join('\n').trim();
        if (pText.isNotEmpty) {
          final isHeader = pText.startsWith('#') ||
              (pText.startsWith('**') && pText.endsWith('**') && !pText.contains('\n'));
          blocks.add(ParagraphBlock(pText, isHeader: isHeader));
        }
        currentParagraphLines.clear();
      }
    }

    void flushBulletList() {
      if (currentBulletItems.isNotEmpty) {
        blocks.add(BulletListBlock(List.from(currentBulletItems)));
        currentBulletItems.clear();
      }
    }

    void flushNumberedList() {
      if (currentNumberedItems.isNotEmpty) {
        blocks.add(NumberedListBlock(List.from(currentNumberedItems)));
        currentNumberedItems.clear();
      }
    }

    void flushExample() {
      if (currentExampleLines.isNotEmpty) {
        blocks.add(ExampleBlock(
          title: 'Example',
          lines: List.from(currentExampleLines),
        ));
        currentExampleLines.clear();
        inExampleSection = false;
      }
    }

    final bulletRegex = RegExp(r'^\s*[\*\-\•]\s+(.+)');
    final numberedRegex = RegExp(r'^\s*\d+[\.\)]\s+(.+)');
    final exampleHeaderRegex = RegExp(r'^\s*(?:\*\*)?Example:?(?:\*\*)?\s*$', caseSensitive: false);
    final userBotDialogueRegex = RegExp(r'^\s*(User|Bot|Assistant|Human|AI):\s*(.+)', caseSensitive: false);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        flushBulletList();
        flushNumberedList();
        flushParagraph();
        flushExample();
        continue;
      }

      // Check Example section header
      if (exampleHeaderRegex.hasMatch(trimmedLine)) {
        flushBulletList();
        flushNumberedList();
        flushParagraph();
        inExampleSection = true;
        continue;
      }

      // Check Dialogue in Example section or general text
      final dialogueMatch = userBotDialogueRegex.firstMatch(trimmedLine);
      if (dialogueMatch != null || (inExampleSection && trimmedLine.isNotEmpty)) {
        flushBulletList();
        flushNumberedList();
        flushParagraph();
        currentExampleLines.add(trimmedLine);
        continue;
      } else if (inExampleSection) {
        flushExample();
      }

      // Check Bullet list item
      final bulletMatch = bulletRegex.firstMatch(line);
      if (bulletMatch != null) {
        flushNumberedList();
        flushParagraph();
        currentBulletItems.add(bulletMatch.group(1)!.trim());
        continue;
      }

      // Check Numbered list item
      final numberedMatch = numberedRegex.firstMatch(line);
      if (numberedMatch != null) {
        flushBulletList();
        flushParagraph();
        currentNumberedItems.add(numberedMatch.group(1)!.trim());
        continue;
      }

      // Standard text line
      flushBulletList();
      flushNumberedList();
      currentParagraphLines.add(line);
    }

    flushBulletList();
    flushNumberedList();
    flushParagraph();
    flushExample();

    return blocks;
  }
}
