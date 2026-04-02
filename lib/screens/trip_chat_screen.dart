import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/trip_service.dart';
import '../widgets/glass_container.dart';

class TripChatScreen extends StatefulWidget {
  final int tripId;
  final String tripName;
  final List<dynamic> members;

  const TripChatScreen({
    super.key,
    required this.tripId,
    required this.tripName,
    required this.members,
  });

  @override
  State<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  final _tripService = const TripService();
  final _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _myId;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages(hideLoading: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool hideLoading = false}) async {
    if (!hideLoading) setState(() => _isLoading = true);
    final results = await _tripService.getTripMessages(widget.tripId);
    final myId = await const AuthService().getUserId();

    if (mounted) {
      final wasAtBottom = _scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50;

      setState(() {
        _myId = myId;
        _messages = results;
        _isLoading = false;
      });

      if (wasAtBottom && _messages.isNotEmpty && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      } else if (!hideLoading && _messages.isNotEmpty && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();

    // Optimistic UI update
    setState(() {
      _messages.add({
        'user_id': int.tryParse(_myId ?? '0') ?? 0,
        'sender_name': 'You',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    await _tripService.addMessage(widget.tripId, text);
    _fetchMessages(hideLoading: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kWhite, size: 20),
        ),
        title: Column(
          children: [
            Text(
              '${widget.tripName} Chat',
              style: const TextStyle(color: kWhite, fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.members.length} Members',
              style: TextStyle(color: kWhite.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kTeal))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _messageBubble(msg, index);
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _messageBubble(dynamic msg, int index) {
    final isMe = msg['user_id'].toString() == _myId;
    final text = msg['message'] ?? '';
    var sender = msg['sender_name'] ?? 'Unknown';
    if (isMe) sender = 'You';

    final dateStr = msg['created_at'] != null ? msg['created_at'].toString().substring(11, 16) : 'Now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                sender,
                style: const TextStyle(color: kTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: kWhite.withValues(alpha: 0.1),
                  child: Text(sender[0].toUpperCase(), style: const TextStyle(color: kWhite, fontSize: 9, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: isMe ? kTeal.withValues(alpha: 0.2) : kWhite.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(color: kWhite, fontSize: 14, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index < 10 ? index * 50 : 0).ms).slideX(begin: isMe ? 0.1 : -0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_rounded, color: kWhite.withValues(alpha: 0.05), size: 100),
          const SizedBox(height: 16),
          Text('Say hello to the group!', style: TextStyle(color: kWhite.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kWhite.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: kWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: kWhite.withValues(alpha: 0.3), fontSize: 14),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: kTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
