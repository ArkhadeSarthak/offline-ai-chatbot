import 'package:flutter/foundation.dart';

class ChatTurn {
  final String sender; // 'user', 'assistant' or 'bot', 'system'
  final String text;

  ChatTurn({required this.sender, required this.text});
}

class ModelChatTemplateService {
  static const String defaultSystemPrompt =
      "You are LocalMind, a helpful offline AI assistant. Answer the user's question directly and accurately.\n"
      "Formatting Instructions:\n"
      "- Structure your response cleanly into short paragraphs separated by line breaks.\n"
      "- Use numbered lists for sequential or step-by-step instructions.\n"
      "- Use bullet points for unordered lists or multiple key points.\n"
      "- Place code snippets inside standard triple-backtick markdown code blocks.\n"
      "- Do not mention being connected to an online service as all responses are generated locally.";

  /// Resolves the canonical template name based on model ID or GGUF filename
  static String resolveTemplate(String templateName, {String? modelId, String? fileName}) {
    final lowerTemplate = templateName.toLowerCase().trim();
    if (lowerTemplate == 'gemma' || lowerTemplate == 'chatml' || lowerTemplate == 'llama3' || lowerTemplate == 'phi3') {
      return lowerTemplate;
    }

    final target = '${modelId ?? ''} ${fileName ?? ''}'.toLowerCase();
    if (target.contains('gemma')) return 'gemma';
    if (target.contains('llama-3') || target.contains('llama3')) return 'llama3';
    if (target.contains('phi-3') || target.contains('phi3')) return 'phi3';
    if (target.contains('qwen') || target.contains('smollm')) return 'chatml';

    return 'chatml';
  }

  /// Returns stop tokens recognized by llama.cpp for the model template
  static List<String> getStopTokens(String templateName) {
    final template = resolveTemplate(templateName);
    switch (template) {
      case 'gemma':
        return ['<end_of_turn>', '<eos>', '<start_of_turn>'];
      case 'chatml':
        return ['<|im_end|>', '<|endoftext|>', '<|im_start|>'];
      case 'llama3':
        return ['<|eot_id|>', '<|end_of_text|>', '<|start_header_id|>'];
      case 'phi3':
        return ['<|end|>', '<|endoftext|>', '<|user|>', '<|assistant|>'];
      default:
        return ['<|im_end|>', '<end_of_turn>', '<|eot_id|>', '<|end|>'];
    }
  }

  /// Builds a fully formatted prompt string according to the active model's chat template specification.
  static String buildPrompt({
    required String userMessage,
    required String templateName,
    List<ChatTurn>? history,
    String? customSystemPrompt,
    int maxContextChars = 6000,
  }) {
    final template = resolveTemplate(templateName);
    final systemPrompt = (customSystemPrompt ?? defaultSystemPrompt).trim();

    // Clean and validate turn ordering (alternating User -> Assistant)
    final List<ChatTurn> cleanTurns = [];

    if (history != null && history.isNotEmpty) {
      for (final turn in history) {
        final text = turn.text.trim();
        if (text.isEmpty) continue;
        final sender = (turn.sender == 'bot') ? 'assistant' : turn.sender;

        if (cleanTurns.isNotEmpty && cleanTurns.last.sender == sender) {
          cleanTurns.last = ChatTurn(
            sender: sender,
            text: '${cleanTurns.last.text}\n$text',
          );
        } else {
          cleanTurns.add(ChatTurn(sender: sender, text: text));
        }
      }
    }

    // Add current user prompt
    final currentUserText = userMessage.trim();
    if (cleanTurns.isEmpty || cleanTurns.last.text != currentUserText) {
      if (cleanTurns.isNotEmpty && cleanTurns.last.sender == 'user') {
        cleanTurns.last = ChatTurn(sender: 'user', text: currentUserText);
      } else {
        cleanTurns.add(ChatTurn(sender: 'user', text: currentUserText));
      }
    }

    // Context truncation safeguard to fit context length limit
    int currentLength = systemPrompt.length + currentUserText.length + 200;
    final List<ChatTurn> truncatedTurns = [];

    for (int i = cleanTurns.length - 1; i >= 0; i--) {
      final turn = cleanTurns[i];
      if (currentLength + turn.text.length > maxContextChars && truncatedTurns.isNotEmpty) {
        debugPrint("[ModelChatTemplateService] Context window limit reached. Truncated older messages.");
        break;
      }
      truncatedTurns.insert(0, turn);
      currentLength += turn.text.length;
    }

    // Format per template
    switch (template) {
      case 'gemma':
        return _formatGemma(systemPrompt, truncatedTurns);
      case 'chatml':
        return _formatChatML(systemPrompt, truncatedTurns);
      case 'llama3':
        return _formatLlama3(systemPrompt, truncatedTurns);
      case 'phi3':
        return _formatPhi3(systemPrompt, truncatedTurns);
      default:
        return _formatChatML(systemPrompt, truncatedTurns);
    }
  }

  /// Gemma 3 / Gemma 2 Chat Template
  /// Format:
  /// <start_of_turn>user
  /// {system_prompt}
  ///
  /// {user_message}<end_of_turn>
  /// <start_of_turn>model
  static String _formatGemma(String systemPrompt, List<ChatTurn> turns) {
    final buffer = StringBuffer();
    bool isFirstUserTurn = true;

    for (final turn in turns) {
      if (turn.sender == 'user') {
        buffer.write('<start_of_turn>user\n');
        if (isFirstUserTurn && systemPrompt.isNotEmpty) {
          buffer.write('$systemPrompt\n\n');
          isFirstUserTurn = false;
        }
        buffer.write('${turn.text}\n<end_of_turn>\n');
      } else if (turn.sender == 'assistant') {
        buffer.write('<start_of_turn>model\n${turn.text}\n<end_of_turn>\n');
      }
    }

    buffer.write('<start_of_turn>model\n');
    return buffer.toString();
  }

  /// ChatML Chat Template (Qwen 2.5, SmolLM2)
  /// Format:
  /// <|im_start|>system
  /// {system_prompt}<|im_end|>
  /// <|im_start|>user
  /// {user_message}<|im_end|>
  /// <|im_start|>assistant
  static String _formatChatML(String systemPrompt, List<ChatTurn> turns) {
    final buffer = StringBuffer();

    if (systemPrompt.isNotEmpty) {
      buffer.write('<|im_start|>system\n$systemPrompt<|im_end|>\n');
    }

    for (final turn in turns) {
      if (turn.sender == 'user') {
        buffer.write('<|im_start|>user\n${turn.text}<|im_end|>\n');
      } else if (turn.sender == 'assistant') {
        buffer.write('<|im_start|>assistant\n${turn.text}<|im_end|>\n');
      }
    }

    buffer.write('<|im_start|>assistant\n');
    return buffer.toString();
  }

  /// Llama 3.2 Chat Template
  /// Format:
  /// <|begin_of_text|><|start_header_id|>system<|end_header_id|>
  ///
  /// {system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>
  ///
  /// {user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>
  ///
  static String _formatLlama3(String systemPrompt, List<ChatTurn> turns) {
    final buffer = StringBuffer();

    buffer.write('<|begin_of_text|>');
    if (systemPrompt.isNotEmpty) {
      buffer.write('<|start_header_id|>system<|end_header_id|>\n\n$systemPrompt<|eot_id|>');
    }

    for (final turn in turns) {
      if (turn.sender == 'user') {
        buffer.write('<|start_header_id|>user<|end_header_id|>\n\n${turn.text}<|eot_id|>');
      } else if (turn.sender == 'assistant') {
        buffer.write('<|start_header_id|>assistant<|end_header_id|>\n\n${turn.text}<|eot_id|>');
      }
    }

    buffer.write('<|start_header_id|>assistant<|end_header_id|>\n\n');
    return buffer.toString();
  }

  /// Phi-3.5 Mini Chat Template
  /// Format:
  /// <|system|>
  /// {system_prompt}<|end|>
  /// <|user|>
  /// {user_message}<|end|>
  /// <|assistant|>
  static String _formatPhi3(String systemPrompt, List<ChatTurn> turns) {
    final buffer = StringBuffer();

    if (systemPrompt.isNotEmpty) {
      buffer.write('<|system|>\n$systemPrompt<|end|>\n');
    }

    for (final turn in turns) {
      if (turn.sender == 'user') {
        buffer.write('<|user|>\n${turn.text}<|end|>\n');
      } else if (turn.sender == 'assistant') {
        buffer.write('<|assistant|>\n${turn.text}<|end|>\n');
      }
    }

    buffer.write('<|assistant|>\n');
    return buffer.toString();
  }
}
