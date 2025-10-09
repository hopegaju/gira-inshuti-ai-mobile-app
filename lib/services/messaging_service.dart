// services/messaging_service.dart
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'ai_priority_service.dart';

class MessagingService extends ChangeNotifier {
  final List<Conversation> _conversations = [];
  final List<Message> _allMessages = [];
  
  List<Conversation> get conversations => List.from(_conversations);
  List<Message> get allMessages => List.from(_allMessages);

  // Get conversations for a specific user
  List<Conversation> getConversationsForUser(String userId, UserRole role) {
    return _conversations.where((conv) {
      if (role == UserRole.user) {
        return conv.userId == userId;
      } else if (role == UserRole.counselor) {
        return conv.counselorId == userId;
      } else if (role == UserRole.admin) {
        return true; // Admins can see all conversations
      }
      return false;
    }).toList();
  }

  // Get messages for a specific conversation
  List<Message> getMessagesForConversation(String conversationId) {
    final conversation = _conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
    return List.from(conversation.messages);
  }

  // Send a new message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? replyToId,
  }) async {
    try {
      // Analyze message with AI
      final analysis = AIPriorityService.analyzeMessage(content);
      
      // Create the message
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        priority: analysis.priority,
        timestamp: DateTime.now(),
        replyToId: replyToId,
        aiEmojis: analysis.suggestedEmojis,
        urgencyScore: analysis.urgencyScore,
      );

      // Find or create conversation
      Conversation? conversation = _conversations.firstWhere(
        (conv) => 
          (conv.userId == senderId && conv.counselorId == receiverId) ||
          (conv.userId == receiverId && conv.counselorId == senderId),
        orElse: () => Conversation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: senderId,
          counselorId: receiverId,
          messages: [],
          lastActivity: DateTime.now(),
          lastMessageStatus: MessageStatus.sent,
        ),
      );

      // If it's a new conversation, add it to the list
      if (!_conversations.contains(conversation)) {
        _conversations.add(conversation);
      }

      // Add message to conversation
      final updatedMessages = List<Message>.from(conversation.messages)..add(message);
      final updatedConversation = Conversation(
        id: conversation.id,
        userId: conversation.userId,
        counselorId: conversation.counselorId,
        messages: updatedMessages,
        lastActivity: DateTime.now(),
        lastMessageStatus: MessageStatus.sent,
        isActive: conversation.isActive,
      );

      // Update the conversation in the list
      final conversationIndex = _conversations.indexWhere((c) => c.id == conversation.id);
      _conversations[conversationIndex] = updatedConversation;

      // Add to all messages list
      _allMessages.add(message);

      // Sort conversations by priority and last activity for counselors
      _sortConversationsByPriority();

      notifyListeners();
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Mark message as read
  Future<bool> markMessageAsRead(String messageId, String userId) async {
    try {
      for (int i = 0; i < _conversations.length; i++) {
        final conversation = _conversations[i];
        final messageIndex = conversation.messages.indexWhere((m) => m.id == messageId);
        
        if (messageIndex != -1) {
          final message = conversation.messages[messageIndex];
          
          // Only mark as read if the current user is the receiver
          if (message.receiverId == userId) {
            final updatedMessage = message.copyWith(status: MessageStatus.read);
            final updatedMessages = List<Message>.from(conversation.messages);
            updatedMessages[messageIndex] = updatedMessage;
            
            _conversations[i] = Conversation(
              id: conversation.id,
              userId: conversation.userId,
              counselorId: conversation.counselorId,
              messages: updatedMessages,
              lastActivity: conversation.lastActivity,
              lastMessageStatus: MessageStatus.read,
              isActive: conversation.isActive,
            );
            
            // Update in all messages list too
            final allMessageIndex = _allMessages.indexWhere((m) => m.id == messageId);
            if (allMessageIndex != -1) {
              _allMessages[allMessageIndex] = updatedMessage;
            }
            
            notifyListeners();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }

  // Get unread message count for a user
  int getUnreadCount(String userId, UserRole role) {
    int count = 0;
    for (final conversation in _conversations) {
      if (role == UserRole.user && conversation.userId == userId) {
        count += conversation.messages
            .where((m) => m.receiverId == userId && m.status != MessageStatus.read)
            .length;
      } else if (role == UserRole.counselor && conversation.counselorId == userId) {
        count += conversation.messages
            .where((m) => m.receiverId == userId && m.status != MessageStatus.read)
            .length;
      }
    }
    return count;
  }

  // Get high priority conversations for counselors
  List<Conversation> getHighPriorityConversations(String counselorId) {
    return _conversations
        .where((conv) => 
          conv.counselorId == counselorId && 
          conv.highestPriority.level >= MessagePriority.high.level)
        .toList()
        ..sort((a, b) => b.highestPriority.level.compareTo(a.highestPriority.level));
  }

  // Sort conversations by priority for counselors
  void _sortConversationsByPriority() {
    _conversations.sort((a, b) {
      // First sort by priority level (highest first)
      final priorityComparison = b.highestPriority.level.compareTo(a.highestPriority.level);
      if (priorityComparison != 0) return priorityComparison;
      
      // Then by last activity (most recent first)
      return b.lastActivity.compareTo(a.lastActivity);
    });
  }

  // Search messages
  List<Message> searchMessages(String query, String userId, UserRole role) {
    final userMessages = _allMessages.where((message) {
      if (role == UserRole.user) {
        return message.senderId == userId || message.receiverId == userId;
      } else if (role == UserRole.counselor) {
        return message.senderId == userId || message.receiverId == userId;
      } else if (role == UserRole.admin) {
        return true;
      }
      return false;
    }).toList();

    return userMessages
        .where((message) => 
          message.content.toLowerCase().contains(query.toLowerCase()))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get conversation between two users
  Conversation? getConversationBetweenUsers(String userId1, String userId2) {
    try {
      return _conversations.firstWhere(
        (conv) => 
          (conv.userId == userId1 && conv.counselorId == userId2) ||
          (conv.userId == userId2 && conv.counselorId == userId1),
      );
    } catch (e) {
      return null;
    }
  }

  // Initialize with some demo messages for testing
  void initializeDemoData() {
    // Create some demo conversations and messages
    final demoConversation = Conversation(
      id: 'demo_conv_1',
      userId: '3', // Assuming user ID 3 exists
      counselorId: '2', // Counselor from auth service
      messages: [],
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
      lastMessageStatus: MessageStatus.sent,
    );

    // Add some demo messages
    final demoMessages = [
      Message(
        id: 'demo_msg_1',
        senderId: '3',
        receiverId: '2',
        content: 'Hello, I\'ve been feeling really anxious lately and need someone to talk to.',
        priority: MessagePriority.high,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        aiEmojis: ['😰', '💛', '🤗', '💚'],
        urgencyScore: 0.6,
      ),
      Message(
        id: 'demo_msg_2',
        senderId: '2',
        receiverId: '3',
        content: 'I\'m here to help. Can you tell me more about what\'s been making you feel anxious?',
        priority: MessagePriority.normal,
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
        status: MessageStatus.read,
        aiEmojis: ['💚', '🤔', '🌟'],
        urgencyScore: 0.1,
      ),
    ];

    final updatedDemoConv = Conversation(
      id: demoConversation.id,
      userId: demoConversation.userId,
      counselorId: demoConversation.counselorId,
      messages: demoMessages,
      lastActivity: demoMessages.last.timestamp,
      lastMessageStatus: demoMessages.last.status,
      isActive: true,
    );

    _conversations.add(updatedDemoConv);
    _allMessages.addAll(demoMessages);
    _sortConversationsByPriority();
  }

  // Clear all data (for testing)
  void clearAllData() {
    _conversations.clear();
    _allMessages.clear();
    notifyListeners();
  }
}