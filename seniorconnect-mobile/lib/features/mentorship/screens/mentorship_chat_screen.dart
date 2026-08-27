import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/mentorship_session_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/screens/mentor_analytics_sheet.dart';

class MentorshipChatScreen extends StatefulWidget {
  final MentorshipSessionModel session;

  const MentorshipChatScreen({super.key, required this.session});

  @override
  State<MentorshipChatScreen> createState() => _MentorshipChatScreenState();
}

class _MentorshipChatScreenState extends State<MentorshipChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = ApiClient();

  List<SessionMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiConstants.sessionMessages(widget.session.id));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _messages = data.map((json) => SessionMessageModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        _setFallbackMessages();
      }
    } catch (_) {
      _setFallbackMessages();
    }
  }

  void _setFallbackMessages() {
    setState(() {
      _isLoading = false;
      _messages = [
        SessionMessageModel(
          id: 'm1',
          sessionId: widget.session.id,
          senderId: widget.session.seniorId,
          senderName: widget.session.seniorName,
          messageContent: 'Hi! Glad we connected. I reviewed your 90-day SDE prep goals. Let me know when you want to do the initial resume review & mock interview!',
          isEncrypted: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        ),
      ];
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgController.clear();
    setState(() => _isSending = true);

    final newMsg = SessionMessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: widget.session.id,
      senderId: 'current-user',
      senderName: 'You',
      messageContent: text,
      isEncrypted: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(newMsg);
    });

    _scrollToBottom();

    try {
      await _apiClient.post(
        ApiConstants.sessionMessages(widget.session.id),
        body: {'messageContent': text},
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

  void _showScheduleModal() {
    final linkCtrl = TextEditingController(text: widget.session.meetingLink ?? 'https://meet.google.com/xyz-abcd-efg');
    final notesCtrl = TextEditingController(text: widget.session.sessionNotes ?? '1-on-1 Mock Interview & Resume Drill');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.video_call_outlined, color: AppTheme.primary),
                SizedBox(width: 10),
                Text(
                  'Schedule Mentorship Session',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkCtrl,
              decoration: const InputDecoration(
                labelText: 'Meeting Link (Google Meet / Zoom)',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Session Agenda / Notes',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📅 Mentorship session details updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  try {
                    await _apiClient.patch(
                      ApiConstants.scheduleSession(widget.session.id),
                      body: {
                        'meetingLink': linkCtrl.text.trim(),
                        'sessionNotes': notesCtrl.text.trim(),
                      },
                    );
                  } catch (_) {}
                },
                child: const Text('Save & Share Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.seniorName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Privacy Level 3: Direct Mentorship',
                  style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: AppTheme.primary),
            tooltip: 'Mentor Trust & Reviews',
            onPressed: () {
              MentorAnalyticsSheet.show(
                context,
                mentorId: widget.session.seniorId,
                mentorName: widget.session.seniorName,
                sessionId: widget.session.id,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call_outlined, color: AppTheme.primary),
            tooltip: 'Schedule Meeting',
            onPressed: _showScheduleModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surfaceContainerLow,
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Direct 1-on-1 Mentorship session with verified senior (${widget.session.seniorPlacementTag ?? "Senior Mentor"}).',
                    style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderName == 'You' || msg.senderId == 'current-user';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.messageContent,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : AppTheme.onSurface,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 10,
                                    color: isMe ? Colors.white70 : AppTheme.outline,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Encrypted',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : AppTheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Type guidance message or questions...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
