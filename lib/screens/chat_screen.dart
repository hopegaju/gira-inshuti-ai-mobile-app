// screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../models/user.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final User otherUser;
  final String? conversationId;

  ChatScreen({
    required this.otherUser,
    this.conversationId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _markMessagesAsRead();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markMessagesAsRead() {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final messagingService = Provider.of<MessagingService>(context, listen: false);
    
    if (currentUser != null && widget.conversationId != null) {
      try {
        final messages = messagingService.getMessagesForConversation(widget.conversationId!);
        for (final message in messages) {
          if (message.receiverId == currentUser.id && message.status != MessageStatus.read) {
            messagingService.markMessageAsRead(message.id, currentUser.id);
          }
        }
      } catch (e) {
        // Conversation might not exist yet
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final messagingService = Provider.of<MessagingService>(context, listen: false);

    if (currentUser != null) {
      setState(() {
        _isTyping = true;
      });

      final success = await messagingService.sendMessage(
        senderId: currentUser.id,
        receiverId: widget.otherUser.id,
        content: content,
      );

      if (success) {
        _messageController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getUserColor(widget.otherUser.role).withOpacity(0.1),
              child: Text(
                widget.otherUser.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _getUserColor(widget.otherUser.role),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.otherUser.roleDisplayName,
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getUserColor(widget.otherUser.role),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer2<AuthService, MessagingService>(
        builder: (context, authService, messagingService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return Center(child: Text('Please log in to chat'));
          }

          List<Message> messages = [];
          if (widget.conversationId != null) {
            try {
              messages = messagingService.getMessagesForConversation(widget.conversationId!);
            } catch (e) {
              // Conversation doesn't exist yet
            }
          }

          return Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser.id;
                          final showTimestamp = index == 0 || 
                              messages[index - 1].timestamp.difference(message.timestamp).inMinutes.abs() > 5;
                          
                          return _buildMessageBubble(
                            message, 
                            isMe, 
                            currentUser, 
                            showTimestamp,
                          );
                        },
                      ),
              ),
              
              // Message input
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isTyping ? null : _sendMessage,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isTyping 
                                ? Colors.grey.shade400 
                                : _getUserColor(widget.otherUser.role),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: _isTyping
                              ? Container(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, User currentUser, bool showTimestamp) {
    return Column(
      children: [
        if (showTimestamp)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? _getUserColor(currentUser.role)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight: isMe ? Radius.circular(4) : null,
                      bottomLeft: !isMe ? Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.grey.shade800,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // AI emojis (visible to counselors only, and only for user messages)
                    if (!isMe && 
                        currentUser.role == UserRole.counselor && 
                        message.aiEmojis.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.aiEmojis.take(3).join(' '),
                              style: TextStyle(fontSize: 12),
                            ),
                            if (message.priority.level >= MessagePriority.high.level) ...[
                              SizedBox(width: 4),
                              Icon(
                                Icons.priority_high,
                                size: 12,
                                color: _getPriorityColor(message.priority),
                              ),
                            ],
                          ],
                        ),
                      ),
                    
                    // Message status
                    if (isMe) ...[
                      Icon(
                        _getStatusIcon(message.status),
                        size: 14,
                        color: _getStatusColor(message.status),
                      ),
                      SizedBox(width: 4),
                    ],
                    
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: _getUserColor(widget.otherUser.role).withOpacity(0.1),
              radius: 40,
              child: Text(
                widget.otherUser.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _getUserColor(widget.otherUser.role),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Start a conversation with ${widget.otherUser.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              widget.otherUser.role == UserRole.counselor
                  ? 'Feel free to share what\'s on your mind. This is a safe space.'
                  : 'Send a message to start the conversation.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getUserColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red.shade700;
      case UserRole.counselor:
        return Colors.green.shade700;
      case UserRole.user:
        return Colors.blue.shade700;
    }
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.critical:
        return Colors.red.shade700;
      case MessagePriority.urgent:
        return Colors.orange.shade600;
      case MessagePriority.high:
        return Colors.amber.shade600;
      case MessagePriority.normal:
        return Colors.blue.shade600;
      case MessagePriority.low:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.replied:
        return Icons.reply;
    }
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Colors.grey.shade500;
      case MessageStatus.delivered:
        return Colors.grey.shade600;
      case MessageStatus.read:
        return Colors.blue.shade600;
      case MessageStatus.replied:
        return Colors.green.shade600;
    }
  }

 String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}