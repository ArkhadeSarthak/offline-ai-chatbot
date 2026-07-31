import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model.dart';
import '../services/model_app_state.dart';

class ChatMessageDto {
  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final String status;

  ChatMessageDto({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = 'success',
  });
}

class ChatThread {
  final String id;
  final String title;
  final List<ChatMessageDto> messages;

  ChatThread({
    required this.id,
    required this.title,
    required this.messages,
  });
}

class ChatScreen extends StatefulWidget {
  final List<AIModel> installedModels;
  final Function(String, String) onSendMessage;
  final bool isGenerating;
  final bool isSidebarOpen;
  final ValueChanged<bool> onToggleSidebar;
  final String selectedModelId;

  const ChatScreen({
    Key? key,
    required this.installedModels,
    required this.onSendMessage,
    required this.isGenerating,
    required this.isSidebarOpen,
    required this.onToggleSidebar,
    required this.selectedModelId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<ChatScreen> {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatThread> _threads = [];
  String? _activeThreadId;
  String? _selectedModelId;
  bool _isGeneratingLocal = false;

  List<AIModel> get _allSelectableModels {
    final List<AIModel> list = [];
    list.addAll(widget.installedModels);
    return list;
  }

  late AnimationController _sidebarAnimationController;
  late Animation<double> _sidebarAnimation;

  Future<void> _saveThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> threadsJson = _threads
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'messages': t.messages
                    .map((m) => {
                          'id': m.id,
                          'sender': m.sender,
                          'text': m.text,
                          'timestamp': m.timestamp,
                          'status': m.status,
                        })
                    .toList(),
              })
          .toList();
      await prefs.setString('chat_threads', jsonEncode(threadsJson));
    } catch (e) {
      debugPrint('Error saving threads: $e');
    }
  }

  Future<void> _loadThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('chat_threads');
      if (data != null) {
        final List decoded = jsonDecode(data);
        setState(() {
          _threads = decoded.map((item) {
            final List msgs = item['messages'] ?? [];
            return ChatThread(
              id: item['id'],
              title: item['title'],
              messages: msgs
                  .map((m) => ChatMessageDto(
                        id: m['id'],
                        sender: m['sender'],
                        text: m['text'],
                        timestamp: m['timestamp'],
                        status: m['status'] ?? 'success',
                      ))
                  .toList(),
            );
          }).toList();

          if (_threads.isNotEmpty) {
            _activeThreadId = _threads.last.id;
          } else {
            _activeThreadId = null;
          }
        });
      } else {
        setState(() {
          _threads = [];
          _activeThreadId = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading threads: $e');
      setState(() {
        _threads = [];
        _activeThreadId = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.selectedModelId;

    _sidebarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    );

    if (widget.isSidebarOpen) {
      _sidebarAnimationController.value = 1.0;
    }

    _loadThreads();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSidebarOpen != oldWidget.isSidebarOpen) {
      if (widget.isSidebarOpen) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    }
    if (widget.selectedModelId != oldWidget.selectedModelId) {
      setState(() {
        _selectedModelId = widget.selectedModelId;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showNoModelDialog(String message) {
    final theme = Theme.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.9 + 0.1 * curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              elevation: 20,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Local Model Needed',
                      style:
                          GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                message,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGeneratingLocal) return;

    final modelAppState = Provider.of<ModelAppState>(context, listen: false);

    // Validate selected model and installation status
    final selectedId = _selectedModelId ?? modelAppState.selectedModelId;
    if (selectedId == null || modelAppState.installedModels.isEmpty) {
      _showNoModelDialog(
          "No models installed. Please go to the Models tab to download an offline AI model.");
      return;
    }

    final isInstalled =
        await modelAppState.modelManager.isModelInstalled(selectedId);
    if (!isInstalled) {
      _showNoModelDialog(
          "The selected model is not installed. Please download it first from the Models tab.");
      return;
    }

    if (_activeThreadId == null) {
      final newId = 'thread-${DateTime.now().millisecondsSinceEpoch}';
      final newThread = ChatThread(
        id: newId,
        title: text.length > 25 ? '${text.substring(0, 22)}...' : text,
        messages: [],
      );
      setState(() {
        _threads.add(newThread);
        _activeThreadId = newId;
      });
    }

    final List<ChatThread> safeThreads = _threads;
    if (safeThreads.isEmpty) return;
    final activeThread = safeThreads.firstWhere((t) => t.id == _activeThreadId,
        orElse: () => safeThreads.first);

    setState(() {
      activeThread.messages.add(
        ChatMessageDto(
          id: 'msg-user-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'user',
          text: text,
          timestamp:
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        ),
      );
      _isGeneratingLocal = true;
    });
    _saveThreads();
    _inputController.clear();
    _scrollToBottom();

    String botResponse = "";
    try {
      // Ensure model is loaded in service
      if (!modelAppState.llmService.isModelLoaded) {
        final path = await modelAppState.modelManager.getModelPath(selectedId);
        if (path != null) {
          await modelAppState.llmService.loadModel(path);
        }
      }

      // Generate response from local LLM
      botResponse = await modelAppState.llmService.generateResponse(text);
    } catch (e) {
      botResponse = "Error generating response: $e";
    }

    setState(() {
      activeThread.messages.add(
        ChatMessageDto(
          id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'bot',
          text: botResponse,
          timestamp:
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        ),
      );
      _isGeneratingLocal = false;
    });

    _saveThreads();
    _scrollToBottom();
  }

  void _startNewChat() {
    final newId = 'thread-${DateTime.now().millisecondsSinceEpoch}';
    final newThread = ChatThread(
      id: newId,
      title: 'New Discussion',
      messages: [
        ChatMessageDto(
          id: 'msg-init-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'bot',
          text: 'How can I assist you today?',
          timestamp:
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
    setState(() {
      _threads.add(newThread);
      _activeThreadId = newId;
      widget.onToggleSidebar(false);
    });
    _saveThreads();
  }

  void _deleteThread(String threadId) {
    setState(() {
      _threads.removeWhere((t) => t.id == threadId);
      if (_activeThreadId == threadId) {
        _activeThreadId = _threads.isNotEmpty ? _threads.first.id : null;
      }
    });
    _saveThreads();
  }

  void _showDeleteConfirmation(String threadId) {
    final theme = Theme.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.9 + 0.1 * curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              elevation: 20,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Delete Chat?',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to delete this conversation? This cannot be undone.',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _deleteThread(threadId);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearAllConfirmation() {
    final theme = Theme.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.9 + 0.1 * curve,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              elevation: 20,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Clear All Chats?',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to delete all chat conversations? This action cannot be undone.',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    setState(() {
                      _threads = [];
                      _activeThreadId = null;
                      widget.onToggleSidebar(false);
                    });
                    _saveThreads();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    // final suggestions = [
    //   "Explain edge computing simply",
    //   "Dart singleton pattern example",
    //   "Benefits of offline local AI",
    //   "Suggest a core workout routine",
    // ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.15)),
              ),
              child: Image.asset(
                'assets/images/Icon.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.psychology,
                    color: theme.colorScheme.primary,
                    size: 48,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LocalMind',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything that you want to get explained.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            // ConstrainedBox(
            //   constraints: const BoxConstraints(maxWidth: 450),
            //   child: GridView.builder(
            //     shrinkWrap: true,
            //     physics: const NeverScrollableScrollPhysics(),
            //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //       crossAxisCount: 2,
            //       crossAxisSpacing: 12,
            //       mainAxisSpacing: 12,
            //       childAspectRatio: 1.6,
            //     ),
            //     itemCount: suggestions.length,
            //     itemBuilder: (context, index) {
            //       final text = suggestions[index];
            //       return InkWell(
            //         onTap: () {
            //           if (_activeThreadId == null) {
            //             _startNewChat();
            //           }
            //           _inputController.text = text;
            //           _handleSubmit();
            //         },
            //         borderRadius: BorderRadius.circular(12),
            //         child: Container(
            //           padding: const EdgeInsets.all(12),
            //           decoration: BoxDecoration(
            //             color: theme.colorScheme.surface,
            //             border: Border.all(
            //                 color: theme.colorScheme.outline.withOpacity(0.15)),
            //             borderRadius: BorderRadius.circular(12),
            //             boxShadow: [
            //               BoxShadow(
            //                 color: Colors.black.withOpacity(0.03),
            //                 blurRadius: 4,
            //                 offset: const Offset(0, 2),
            //               )
            //             ],
            //           ),
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Icon(Icons.bolt,
            //                   size: 16, color: theme.colorScheme.secondary),
            //               const Spacer(),
            //               Text(
            //                 text,
            //                 style: GoogleFonts.inter(
            //                   fontSize: 11,
            //                   fontWeight: FontWeight.w500,
            //                   color:
            //                       theme.colorScheme.onSurface.withOpacity(0.8),
            //                 ),
            //                 maxLines: 3,
            //                 overflow: TextOverflow.ellipsis,
            //               ),
            //             ],
            //           ),
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final List<ChatThread> safeThreads = _threads;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Chats',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48), // Prevent overlap with X button
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeThreadId = null;
                    widget.onToggleSidebar(false);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NEW CHAT',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: safeThreads.isEmpty
                  ? Center(
                      child: Text(
                        'No recent chats',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      itemCount: safeThreads.length,
                      itemBuilder: (context, index) {
                        final thread = safeThreads[index];
                        final isActive = thread.id == _activeThreadId;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary.withOpacity(0.08)
                                : Colors.transparent,
                            border: Border.all(
                              color: isActive
                                  ? theme.colorScheme.primary.withOpacity(0.25)
                                  : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.only(left: 12.0, right: 4.0),
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                              size: 16,
                            ),
                            title: Text(
                              thread.title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isActive
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _activeThreadId = thread.id;
                                widget.onToggleSidebar(false);
                              });
                            },
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              onSelected: (value) {
                                if (value == 'open') {
                                  setState(() {
                                    _activeThreadId = thread.id;
                                    widget.onToggleSidebar(false);
                                  });
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(thread.id);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline,
                                          size: 16,
                                          color: theme.colorScheme.onSurface),
                                      const SizedBox(width: 8),
                                      const Text('Open Chat',
                                          style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          size: 16, color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text('Delete Chat',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // Model Selection Dropdown Container
            if (widget.installedModels.length >= 2)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Model',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.15),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.installedModels
                                  .any((m) => m.id == _selectedModelId)
                              ? _selectedModelId
                              : widget.installedModels.first.id,
                          isExpanded: true,
                          dropdownColor: theme.colorScheme.surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          items: widget.installedModels.map((m) {
                            return DropdownMenuItem<String>(
                              value: m.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.psychology_outlined,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          m.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${m.quantization} • ${m.size}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedModelId = newValue;
                              });
                              Provider.of<ModelAppState>(context, listen: false)
                                  .selectModel(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (safeThreads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton(
                  onPressed: _showClearAllConfirmation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_sweep_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'CLEAR ALL CHATS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _preprocessText(String text) {
    // Add line break before numbered points (if not at the start of text and not already after a newline)
    String processed = text.replaceAllMapped(RegExp(r'(\d+\.\s)'), (match) {
      if (match.start == 0) {
        return match.group(1)!;
      }
      final beforeMatch = text.substring(0, match.start);
      if (beforeMatch.endsWith('\n') || beforeMatch.trim().endsWith('\n')) {
        return match.group(1)!;
      }
      return '\n${match.group(1)}';
    });

    // Process bullet points line-by-line
    final lines = processed.split('\n');
    final bulletRegex = RegExp(r'^\s*[\*-]\s+');
    for (int i = 0; i < lines.length; i++) {
      if (bulletRegex.hasMatch(lines[i])) {
        lines[i] = lines[i].replaceFirst(bulletRegex, '• ');
      }
    }

    return lines.join('\n');
  }

  List<InlineSpan> _parseInlineSpans(String text, TextStyle defaultStyle) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*)|(\*.*?\*)');
    int start = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: defaultStyle,
        ));
      }

      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        final innerText = matchText.substring(2, matchText.length - 2);
        spans.add(TextSpan(
          text: innerText,
          style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        final innerText = matchText.substring(1, matchText.length - 1);
        spans.add(TextSpan(
          text: innerText,
          style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }

    return spans;
  }

  Widget _buildFormattedText(String text, bool isMe, ThemeData theme) {
    final defaultStyle = GoogleFonts.inter(
      fontSize: 13.5,
      color: isMe ? Colors.black : theme.colorScheme.onSurface,
      height: 1.45,
    );

    final preprocessed = _preprocessText(text);
    final spans = _parseInlineSpans(preprocessed, defaultStyle);

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildMessageBubble(ChatMessageDto msg, bool isMe, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildAvatar(Icons.android_outlined, theme),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : theme.colorScheme.surface,
                border: isMe
                    ? null
                    : Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.12)),
                borderRadius: BorderRadius.only(
                  topLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  topRight: isMe ? Radius.zero : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(msg.text, isMe, theme),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.timestamp,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: isMe
                              ? Colors.black.withOpacity(0.6)
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.done_all,
                            size: 12, color: Colors.black),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (isMe) _buildAvatar(Icons.person_outline, theme),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(Icons.android_outlined, theme),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.12)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const PulseThinkingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(IconData icon, ThemeData theme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: theme.colorScheme.primary),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor.withOpacity(0.0),
            theme.scaffoldBackgroundColor.withOpacity(0.45),
            theme.scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        enabled: !_isGeneratingLocal,
                        style: TextStyle(
                            fontSize: 13, color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Message Local AI...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4)),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onSubmitted: (_) => _handleSubmit(),
                      ),
                    ),
                    InkWell(
                      onTap: _handleSubmit,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward,
                            size: 18, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final List<ChatThread> safeThreads = _threads;
    final activeThread = safeThreads.isNotEmpty && _activeThreadId != null
        ? safeThreads.firstWhere((t) => t.id == _activeThreadId,
            orElse: () => safeThreads.first)
        : null;

    return Stack(
      children: [
        // Main Screen Content (shifted when sidebar is open)
        AnimatedBuilder(
          animation: _sidebarAnimation,
          builder: (context, child) {
            final double animVal = _sidebarAnimation.value;
            final double translationX = 80.0 * animVal;
            final double scaleVal = 1.0 - 0.05 * animVal;
            final double borderRadiusVal = 16.0 * animVal;

            return Transform.translate(
              offset: Offset(translationX, 0),
              child: Transform.scale(
                scale: scaleVal,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadiusVal),
                  child: Container(
                    color: theme.scaffoldBackgroundColor,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Stack(
            children: [
              // Scrollable Chat History or Empty State
              Positioned.fill(
                child: activeThread == null
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 48.0, // Space for the floating menu button
                          bottom: 96.0, // Bottom padding to not obscure content behind transparent input
                        ),
                        itemCount: activeThread.messages.length +
                            (_isGeneratingLocal ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == activeThread.messages.length) {
                            return _buildThinkingBubble(theme);
                          }
                          final msg = activeThread.messages[index];
                          final isMe = msg.sender == 'user';
                          return _buildMessageBubble(msg, isMe, theme);
                        },
                      ),
              ),

              // Bottom Input text pill form
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildInputArea(theme),
              ),
            ],
          ),
        ),

        // Sidebar Dimming Overlay (with Blur)
        AnimatedBuilder(
          animation: _sidebarAnimation,
          builder: (context, child) {
            final double animVal = _sidebarAnimation.value;
            if (animVal == 0.0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => widget.onToggleSidebar(false),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 5.0 * animVal,
                    sigmaY: 5.0 * animVal,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * animVal),
                  ),
                ),
              ),
            );
          },
        ),

        // Sidebar content container (slides in from left)
        AnimatedBuilder(
          animation: _sidebarAnimation,
          builder: (context, child) {
            final double animVal = _sidebarAnimation.value;
            final double xOffset = -280.0 * (1.0 - animVal);
            return Positioned(
              left: xOffset,
              top: 0,
              bottom: 0,
              width: 280.0,
              child: _buildSidebar(theme),
            );
          },
        ),

        // Floating Animated Menu Button (moves together with sidebar)
        if (_threads.isNotEmpty)
          AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              final double animVal = _sidebarAnimation.value;
              final bool isSidebarVisible = animVal > 0.05;
              // Moves from left: 4.0 to left: 220.0 (inside sidebar top right)
              final double buttonLeft = 4.0 + 216.0 * animVal;
              final double buttonTop = 4.0;

              return Positioned(
                left: buttonLeft,
                top: buttonTop,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isSidebarVisible ? 0.0 : 5.0,
                      sigmaY: isSidebarVisible ? 0.0 : 5.0,
                    ),
                    child: Container(
                      margin: EdgeInsets.only(left: isSidebarVisible ? 0 : 8),
                      decoration: BoxDecoration(
                        color: isSidebarVisible
                            ? Colors.transparent
                            : theme.colorScheme.surface.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: isSidebarVisible
                            ? null
                            : Border.all(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.15),
                                width: 1,
                              ),
                      ),
                      child: IconButton(
                        icon: AnimatedIcon(
                          icon: AnimatedIcons.menu_close,
                          progress: _sidebarAnimation,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        onPressed: () {
                          widget.onToggleSidebar(!widget.isSidebarOpen);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class PulseThinkingIndicator extends StatefulWidget {
  const PulseThinkingIndicator({Key? key}) : super(key: key);

  @override
  State<PulseThinkingIndicator> createState() => _PulseThinkingIndicatorState();
}

class _PulseThinkingIndicatorState extends State<PulseThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2 * _animation.value,
                      )
                    ]),
              ),
              const SizedBox(width: 8),
              Text(
                'THINKING LOCALLY...',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

export_chat_example() {}
