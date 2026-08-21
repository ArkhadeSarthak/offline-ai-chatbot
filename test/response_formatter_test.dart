import 'package:flutter_test/flutter_test.dart';
import 'package:local_mind/services/response_formatter.dart';

void main() {
  group('ResponseSanitizer Tests', () {
    test('sanitizes null/empty text gracefully', () {
      expect(ResponseSanitizer.sanitize(''), equals('No content received.'));
      expect(
        ResponseSanitizer.sanitize('', status: 'error'),
        equals('An error occurred while generating the response. Please try again.'),
      );
    });

    test('extracts text from raw JSON output', () {
      const jsonStr = '{"response": "Hello world from model"}';
      expect(ResponseSanitizer.sanitize(jsonStr), equals('Hello world from model'));

      const jsonError = '{"error": "Model out of memory"}';
      expect(ResponseSanitizer.sanitize(jsonError), equals('API Error: Model out of memory'));
    });

    test('strips stop tokens', () {
      const input = 'Hello world<|im_end|><end_of_turn>';
      expect(ResponseSanitizer.sanitize(input), equals('Hello world'));
    });
  });

  group('ResponseBlockParser Tests', () {
    test('parses code blocks correctly', () {
      const input = '''Here is Dart code:
```dart
void main() {
  print("Hello");
}
```
Done.''';

      final blocks = ResponseBlockParser.parse(input);
      expect(blocks.length, equals(3));
      expect(blocks[0], isA<ParagraphBlock>());
      expect(blocks[1], isA<CodeBlock>());

      final codeBlock = blocks[1] as CodeBlock;
      expect(codeBlock.language, equals('DART'));
      expect(codeBlock.code, contains('void main()'));

      expect(blocks[2], isA<ParagraphBlock>());
    });

    test('parses bullet lists and numbered lists', () {
      const input = '''Key features:
* Speed
* Security
* Offline access

Steps:
1. Install
2. Select model
3. Chat''';

      final blocks = ResponseBlockParser.parse(input);
      expect(blocks.length, equals(4));

      expect(blocks[0], isA<ParagraphBlock>());
      expect(blocks[1], isA<BulletListBlock>());
      expect((blocks[1] as BulletListBlock).items.length, equals(3));

      expect(blocks[2], isA<ParagraphBlock>());
      expect(blocks[3], isA<NumberedListBlock>());
      expect((blocks[3] as NumberedListBlock).items.length, equals(3));
    });

    test('parses example blocks correctly', () {
      const input = '''Example:
User: Hello
Bot: Hi there! How can I help?''';

      final blocks = ResponseBlockParser.parse(input);
      expect(blocks.length, equals(1));
      expect(blocks[0], isA<ExampleBlock>());

      final exampleBlock = blocks[0] as ExampleBlock;
      expect(exampleBlock.lines.length, equals(2));
      expect(exampleBlock.lines[0], contains('User: Hello'));
    });

    test('handles error status', () {
      final blocks = ResponseBlockParser.parse('Network failure', status: 'error');
      expect(blocks.length, equals(1));
      expect(blocks[0], isA<ErrorBlock>());
      expect((blocks[0] as ErrorBlock).message, equals('Network failure'));
    });
  });
}
