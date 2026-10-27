import 'package:flutter/material.dart';

import '../../services/ai_coach_service.dart';
import '../../services/gemini_service.dart';
import '../../services/coach_hybrid_router.dart';
import '../../services/ai_chat_history_service.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;

  final List<Map<String, String>> _chatHistory = [];

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Xin chào! 👋 Tôi là FITTRACK AI Coach.\n\n'
          'Tôi có thể giúp bạn phân tích tập luyện, dinh dưỡng '
          'và tiến độ sức khỏe.',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final savedHistory = await AiChatHistoryService.loadHistory();

    if (!mounted) return;

    setState(() {
      _chatHistory
        ..clear()
        ..addAll(savedHistory);

      _messages.clear();

      if (savedHistory.isEmpty) {
        _messages.add(
          const _ChatMessage(
            text:
                'Xin chào 👋 Tôi là FITTRACK AI Coach.\n\n'
                'Tôi có thể giúp bạn phân tích tập luyện, '
                'dinh dưỡng và tiến độ sức khỏe.',
            isUser: false,
          ),
        );
      }

      for (final message in savedHistory) {
        final text = message['text'];

        if (text == null || text.isEmpty) {
          continue;
        }

        _messages.add(
          _ChatMessage(text: text, isUser: message['role'] == 'user'),
        );
      }
    });

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? quickPrompt}) async {
    final text = (quickPrompt ?? _messageController.text).trim();

    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));

      _isLoading = true;
    });

    if (quickPrompt == null) {
      _messageController.clear();
    }

    _chatHistory.add({'role': 'user', 'text': text});

    await AiChatHistoryService.saveHistory(_chatHistory);

    _scrollToBottom();

    try {
      final historyForAi = _chatHistory.length > 1
          ? _chatHistory.sublist(0, _chatHistory.length - 1)
          : <Map<String, String>>[];

      final recentHistory = historyForAi.length > 10
          ? historyForAi.sublist(historyForAi.length - 10)
          : historyForAi;

      // AI Coach 3.0: cố gắng trả lời từ dữ liệu FITTRACK trước.
      // Chỉ câu hỏi chưa hỗ trợ mới gọi Gemini.
      final routed = await CoachHybridRouter.route(text);
      final response = routed != null
          ? routed.answer
          : await GeminiService.ask(text, history: recentHistory);

      if (!mounted) return;

      // Mặc định sử dụng câu trả lời của Gemini.
      var finalResponse = response;

      // Nếu Gemini đang lỗi/quá tải/hết quota,
      // FITTRACK sẽ tự phân tích dữ liệu hiện tại.

      final geminiUnavailable =
          response.contains('Gemini đang quá tải') ||
          response.contains('Gemini đang tạm thời không khả dụng') ||
          response.contains('giới hạn yêu cầu Gemini') ||
          response.contains('Không thể kết nối AI') ||
          response.contains('Không thể kết nối FITTRACK AI') ||
          response.contains('Không thể kết nối máy chủ FITTRACK AI') ||
          response.contains('FITTRACK AI chưa tạo được câu trả lời');

      if (geminiUnavailable && routed == null) {
        // Don't answer an unrelated question with today's health metrics.
        // A generic question must never silently fall back to analyzeToday().
        finalResponse =
            'Mình chưa thể trả lời chính xác câu hỏi này vì Gemini '
            'hiện không khả dụng. Đây là câu hỏi nằm ngoài phạm vi '
            'bộ xử lý nội bộ FITTRACK AI. Bạn thử lại khi kết nối AI '
            'hoạt động nhé.';
      }

      setState(() {
        _isLoading = false;
      });

      _chatHistory.add({'role': 'assistant', 'text': finalResponse});

      await AiChatHistoryService.saveHistory(_chatHistory);

      _addAiResponse(finalResponse);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _addAiResponse(
        'Không thể nhận phản hồi từ FITTRACK AI. Vui lòng thử lại.',
      );
    }
  }

  Future<void> _startNewChat() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text(
            'Cuộc trò chuyện mới',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Lịch sử trò chuyện hiện tại sẽ bị xóa. '
            'Bạn có muốn bắt đầu cuộc trò chuyện mới không?',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Chat mới'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    await AiChatHistoryService.clearHistory();

    if (!mounted) return;

    setState(() {
      _chatHistory.clear();

      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text:
                'Xin chào 👋 Tôi là FITTRACK AI Coach.\n\n'
                'Tôi có thể giúp bạn phân tích tập luyện, '
                'dinh dưỡng và tiến độ sức khỏe.',
            isUser: false,
          ),
        );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _addAiResponse(String response) {
    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
    });

    _scrollToBottom();
  }

  Future<void> _runQuickAction(String question, String answer) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;

      _messages.add(_ChatMessage(text: question, isUser: true));

      _messages.add(_ChatMessage(text: answer, isUser: false));
    });

    _scrollToBottom();

    try {
      _chatHistory.add({'role': 'user', 'text': question});

      await AiChatHistoryService.saveHistory(_chatHistory);

      _chatHistory.add({'role': 'assistant', 'text': answer});

      await AiChatHistoryService.saveHistory(_chatHistory);
    } catch (e) {
      debugPrint('AI COACH QUICK ACTION ERROR: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1B2E),
        elevation: 0,
        toolbarHeight: 74,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF087F9D), Color(0xFF493B91)],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF64E5FF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C8FF).withValues(alpha: 0.17),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FITTRACK AI Coach',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Trợ lý sức khỏe cá nhân',
                    style: TextStyle(color: Color(0xFFA8C0D4), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bắt đầu cuộc trò chuyện mới',
            onPressed: _isLoading ? null : _startNewChat,
            icon: const Icon(
              Icons.add_comment_rounded,
              color: Color(0xFF4BDDFF),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF081D2D),
                    Color(0xFF090F20),
                    Color(0xFF1D1335),
                    Color(0xFF080D19),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -140,
            child: IgnorePointer(
              child: Container(
                height: 410,
                width: 410,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00CCFF).withValues(alpha: 0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -130,
            child: IgnorePointer(
              child: Container(
                height: 420,
                width: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9B6CFF).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildQuickActions(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth > 1050
                          ? (constraints.maxWidth - 1000) / 2
                          : 14.0;

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          22,
                          horizontalPadding,
                          25,
                        ),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isLoading) {
                            return _buildThinkingMessage();
                          }

                          return _buildMessage(_messages[index]);
                        },
                      );
                    },
                  ),
                ),
                _buildInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A3D), Color(0xFF161D35)],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF4BDDFF).withValues(alpha: 0.15),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        children: [
          _quickButton(
            icon: Icons.analytics_rounded,
            text: 'Phân tích hôm nay',
            onTap: () {
              _runQuickAction(
                'Phân tích hôm nay',
                AiCoachService.analyzeToday(),
              );
            },
          ),
          _quickButton(
            icon: Icons.fitness_center_rounded,
            text: 'Gợi ý tập luyện',
            onTap: () {
              _runQuickAction(
                'Gợi ý tập luyện',
                AiCoachService.suggestWorkout(),
              );
            },
          ),
          _quickButton(
            icon: Icons.restaurant_menu_rounded,
            text: 'Gợi ý dinh dưỡng',
            onTap: () {
              _runQuickAction(
                'Gợi ý dinh dưỡng',
                AiCoachService.suggestNutrition(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _quickButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: _CoachQuickChip(
        icon: icon,
        text: text,
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  Widget _buildThinkingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF086F91), Color(0xFF443482)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF182C43), Color(0xFF1C203A)],
                ),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: const Color(0xFF39CCFF).withValues(alpha: 0.24),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CoachTypingDots(),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'FITTRACK AI đang suy nghĩ...',
                      style: TextStyle(color: Color(0xFFBCD3E3), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    final isUser = message.isUser;

    return TweenAnimationBuilder<double>(
      key: ValueKey(message),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(
              (isUser ? 14 : -14) * (1 - animation),
              12 * (1 - animation),
            ),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF087D9D), Color(0xFF493686)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 620),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF65E7FF), Color(0xFF08B6F0)],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF192D43), Color(0xFF191D34)],
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(21),
                    topRight: const Radius.circular(21),
                    bottomLeft: Radius.circular(isUser ? 21 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 21),
                  ),
                  border: Border.all(
                    color: isUser
                        ? const Color(0xFF7CEDFF)
                        : const Color(0xFF3DD4FF).withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? const Color(0xFF00C9F5).withValues(alpha: 0.14)
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: 17,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: Color(0xFF61E4FF),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'FITTRACK AI',
                            style: TextStyle(
                              color: Color(0xFF61E4FF),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? const Color(0xFF061624)
                            : const Color(0xFFEAF4FF),
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102238), Color(0xFF19152E)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00C8FF).withValues(alpha: 0.18),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Hỏi FITTRACK AI...',
                    hintStyle: const TextStyle(color: Color(0xFF8DA7BB)),
                    prefixIcon: const Icon(
                      Icons.auto_awesome_outlined,
                      color: Color(0xFF4BDDFF),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF101D32),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: const Color(0xFF4BDDFF).withValues(alpha: 0.19),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF4BDDFF),
                        width: 1.5,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF29384F)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 53,
                height: 53,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? const LinearGradient(
                          colors: [Color(0xFF34465B), Color(0xFF29354C)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF6DE6FF), Color(0xFF00B7ED)],
                        ),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF00C8F8)
                                .withValues(alpha: 0.25),
                            blurRadius: 19,
                          ),
                        ],
                ),
                child: IconButton(
                  tooltip: 'Gửi tin nhắn',
                  onPressed: _isLoading
                      ? null
                      : () {
                          _sendMessage();
                        },
                  icon: Icon(
                    _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_upward_rounded,
                    color: _isLoading
                        ? Colors.white54
                        : const Color(0xFF061624),
                    size: 25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachTypingDots extends StatefulWidget {
  const _CoachTypingDots();

  @override
  State<_CoachTypingDots> createState() => _CoachTypingDotsState();
}

class _CoachTypingDotsState extends State<_CoachTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final activeDot = (_controller.value * 3).floor();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final active = index == activeDot;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: active ? 9 : 6,
              height: active ? 9 : 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF59E5FF)
                    : const Color(0xFF47677E),
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00D5FF)
                              .withValues(alpha: 0.45),
                          blurRadius: 9,
                        ),
                      ]
                    : [],
              ),
            );
          }),
        );
      },
    );
  }
}

class _CoachQuickChip extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _CoachQuickChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  State<_CoachQuickChip> createState() => _CoachQuickChipState();
}

class _CoachQuickChipState extends State<_CoachQuickChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered && widget.onTap != null;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
      },
      child: AnimatedScale(
        scale: active ? 1.035 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? [const Color(0xFF1B5368), const Color(0xFF34275F)]
                  : [const Color(0xFF173247), const Color(0xFF1B2039)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active ? const Color(0xFF58E5FF) : const Color(0xFF385367),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C8FF).withValues(alpha: 0.17),
                      blurRadius: 17,
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: const Color(0xFF52DEFF), size: 18),
                    const SizedBox(width: 9),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: Color(0xFF6A9BB2),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}
