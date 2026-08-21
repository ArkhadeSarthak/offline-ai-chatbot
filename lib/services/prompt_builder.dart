import 'model_chat_template_service.dart';

class ChatMessageItem {
  final String sender; // 'user', 'bot' or 'assistant', 'system'
  final String text;

  ChatMessageItem({required this.sender, required this.text});
}

class PromptBuilder {
  static const String defaultSystemPrompt = ModelChatTemplateService.defaultSystemPrompt;

  /// Generates a model-aware prompt from the current message and optional history using ModelChatTemplateService.
  static String buildPrompt({
    required String userMessage,
    required String chatTemplate,
    List<ChatMessageItem>? history,
    String? customSystemPrompt,
    int maxContextChars = 6000,
  }) {
    final turns = history
        ?.map((h) => ChatTurn(sender: h.sender, text: h.text))
        .toList();

    return ModelChatTemplateService.buildPrompt(
      userMessage: userMessage,
      templateName: chatTemplate,
      history: turns,
      customSystemPrompt: customSystemPrompt,
      maxContextChars: maxContextChars,
    );
  }

  /// Clean special stop tokens from completed model output
  static String cleanStopTokens(String text, {String? templateName}) {
    String cleaned = text;
    final stopTokens = [
      '<end_of_turn>',
      '<|im_end|>',
      '<|eot_id|>',
      '<|end|>',
      '<|endoftext|>',
      '<eos>',
      '<|begin_of_text|>',
      '<start_of_turn>',
      '<|im_start|>',
      '<|system|>',
      '<|user|>',
      '<|assistant|>',
      '[INST]',
      '[/INST]',
    ];

    if (templateName != null) {
      stopTokens.addAll(ModelChatTemplateService.getStopTokens(templateName));
    }

    for (final token in stopTokens) {
      cleaned = cleaned.replaceAll(token, '');
    }

    return cleaned.trim();
  }

  static List<String> getStopTokensForTemplate(String chatTemplate) {
    return ModelChatTemplateService.getStopTokens(chatTemplate);
  }
}

/// Buffer helper to catch and strip stop tokens split across multi-chunk streams
class StreamStopTokenCleaner {
  final List<String> stopTokens;
  String _pendingBuffer = '';

  StreamStopTokenCleaner(this.stopTokens);

  /// Process incoming token chunk and yield only safe, fully validated content
  String processChunk(String chunk) {
    _pendingBuffer += chunk;

    // Check if pending buffer contains any completed stop token
    for (final token in stopTokens) {
      if (_pendingBuffer.contains(token)) {
        _pendingBuffer = _pendingBuffer.replaceAll(token, '');
      }
    }

    // Check if buffer ends with a partial prefix of any stop token
    bool matchesPartial = false;
    for (final token in stopTokens) {
      for (int i = 1; i <= token.length && i <= _pendingBuffer.length; i++) {
        if (_pendingBuffer.endsWith(token.substring(0, i))) {
          matchesPartial = true;
          break;
        }
      }
      if (matchesPartial) break;
    }

    if (matchesPartial) {
      // Hold back potential partial stop token
      return '';
    } else {
      final output = _pendingBuffer;
      _pendingBuffer = '';
      return output;
    }
  }

  /// Flush remaining buffer content when stream ends
  String flush() {
    for (final token in stopTokens) {
      _pendingBuffer = _pendingBuffer.replaceAll(token, '');
    }
    final output = _pendingBuffer;
    _pendingBuffer = '';
    return output;
  }
}
