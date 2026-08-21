import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/response_formatter.dart';

/// Main entry point widget for rendering AI and user responses in a clean,
/// mobile-friendly, and consistently structured block format with safe fallback.
class FormattedResponseView extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? status;

  const FormattedResponseView({
    Key? key,
    required this.text,
    required this.isMe,
    this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (text.isEmpty && status == 'generating') {
      return const SizedBox.shrink();
    }

    try {
      final blocks = ResponseBlockParser.parse(text, status: status);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final isLast = index == blocks.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : 10.0),
            child: _buildBlockWidget(context, block, theme),
          );
        }).toList(),
      );
    } catch (e) {
      // Safe Plain Text Fallback to prevent white/gray blank screen or UI crash
      return SelectableText(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          color: isMe ? Colors.black : theme.colorScheme.onSurface,
          height: 1.5,
        ),
      );
    }
  }

  Widget _buildBlockWidget(
      BuildContext context, ResponseBlock block, ThemeData theme) {
    if (block is ParagraphBlock) {
      return _ParagraphBlockWidget(
          block: block, isMe: isMe, theme: theme);
    } else if (block is BulletListBlock) {
      return _BulletListWidget(
          block: block, isMe: isMe, theme: theme);
    } else if (block is NumberedListBlock) {
      return _NumberedListWidget(
          block: block, isMe: isMe, theme: theme);
    } else if (block is CodeBlock) {
      return CodeBlockWidget(block: block, theme: theme);
    } else if (block is ExampleBlock) {
      return _ExampleBlockWidget(
          block: block, isMe: isMe, theme: theme);
    } else if (block is ErrorBlock) {
      return _ErrorBlockWidget(block: block, theme: theme);
    }
    return const SizedBox.shrink();
  }
}

/// Formats inline spans (bold, italic, inline code) safely without showing raw markdown symbols.
class FormattedInlineText extends StatelessWidget {
  final String text;
  final TextStyle defaultStyle;
  final bool isHeader;

  const FormattedInlineText({
    Key? key,
    required this.text,
    required this.defaultStyle,
    this.isHeader = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String cleanText = text;

    // Strip leading header symbols if present
    if (isHeader) {
      cleanText = cleanText.replaceAll(RegExp(r'^#+\s*'), '');
      cleanText = cleanText.replaceAll(RegExp(r'^\*\*|\*\*$'), '');
    }

    final effectiveStyle = isHeader
        ? defaultStyle.copyWith(
            fontSize: defaultStyle.fontSize! + 2,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          )
        : defaultStyle;

    try {
      final spans = _parseSpans(cleanText, effectiveStyle, context);

      return SelectableText.rich(
        TextSpan(children: spans),
        style: effectiveStyle,
      );
    } catch (e) {
      return SelectableText(
        cleanText,
        style: effectiveStyle,
      );
    }
  }

  List<InlineSpan> _parseSpans(
      String rawText, TextStyle baseStyle, BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*)|(\*.*?\*)|(`.*?`)');
    int start = 0;

    for (final match in regex.allMatches(rawText)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: rawText.substring(start, match.start),
          style: baseStyle,
        ));
      }

      final matchStr = match.group(0)!;

      if (matchStr.startsWith('**') && matchStr.endsWith('**') && matchStr.length >= 4) {
        spans.add(TextSpan(
          text: matchStr.substring(2, matchStr.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchStr.startsWith('*') && matchStr.endsWith('*') && matchStr.length >= 2) {
        spans.add(TextSpan(
          text: matchStr.substring(1, matchStr.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchStr.startsWith('`') && matchStr.endsWith('`') && matchStr.length >= 2) {
        final theme = Theme.of(context);
        spans.add(TextSpan(
          text: ' ${matchStr.substring(1, matchStr.length - 1)} ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: (baseStyle.fontSize ?? 13.5) - 1.0,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            fontWeight: FontWeight.w600,
          ),
        ));
      }

      start = match.end;
    }

    if (start < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(start),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

class _ParagraphBlockWidget extends StatelessWidget {
  final ParagraphBlock block;
  final bool isMe;
  final ThemeData theme;

  const _ParagraphBlockWidget({
    Key? key,
    required this.block,
    required this.isMe,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 13.5,
      color: isMe ? Colors.black : theme.colorScheme.onSurface,
      height: 1.5,
    );

    return FormattedInlineText(
      text: block.text,
      defaultStyle: style,
      isHeader: block.isHeader,
    );
  }
}

class _BulletListWidget extends StatelessWidget {
  final BulletListBlock block;
  final bool isMe;
  final ThemeData theme;

  const _BulletListWidget({
    Key? key,
    required this.block,
    required this.isMe,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 13.5,
      color: isMe ? Colors.black : theme.colorScheme.onSurface,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: block.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7, right: 10, left: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.black87
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: FormattedInlineText(
                  text: item,
                  defaultStyle: style,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NumberedListWidget extends StatelessWidget {
  final NumberedListBlock block;
  final bool isMe;
  final ThemeData theme;

  const _NumberedListWidget({
    Key? key,
    required this.block,
    required this.isMe,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 13.5,
      color: isMe ? Colors.black : theme.colorScheme.onSurface,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: block.items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.black.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$index',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.black : theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: FormattedInlineText(
                  text: item,
                  defaultStyle: style,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Mobile-friendly horizontally scrollable Code Block widget with language tag
/// and copy button.
class CodeBlockWidget extends StatefulWidget {
  final CodeBlock block;
  final ThemeData theme;

  const CodeBlockWidget({
    Key? key,
    required this.block,
    required this.theme,
  }) : super(key: key);

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _isCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.block.code));
    setState(() {
      _isCopied = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1E1E2E);
    const headerBgColor = Color(0xFF181825);
    const textColor = Color(0xFFCDD6F4);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Language Badge and Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 14,
                      color: widget.theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.block.language,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _isCopied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          size: 13,
                          color: _isCopied
                              ? Colors.greenAccent
                              : textColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCopied ? 'COPIED' : 'COPY',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isCopied
                                ? Colors.greenAccent
                                : textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code Content with Horizontal Scroll for Mobile Compatibility
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.block.code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12.5,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleBlockWidget extends StatelessWidget {
  final ExampleBlock block;
  final bool isMe;
  final ThemeData theme;

  const _ExampleBlockWidget({
    Key? key,
    required this.block,
    required this.isMe,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 13.0,
      color: theme.colorScheme.onSurface,
      height: 1.45,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                block.title.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...block.lines.map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: FormattedInlineText(
                text: line,
                defaultStyle: style,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _ErrorBlockWidget extends StatelessWidget {
  final ErrorBlock block;
  final ThemeData theme;

  const _ErrorBlockWidget({
    Key? key,
    required this.block,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              block.message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.redAccent,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
