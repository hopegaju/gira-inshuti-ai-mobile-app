import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'ai_priority_service.dart';

class MessagingService extends ChangeNotifier {
  final List<Conversation> _conversations = [];
  final List<Message> _allMessages = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFirebaseMode = true;
  
  List<Conversation> get conversations => List.from(_conversations);
  List<Message> get allMessages => List.from(_allMessages);

  // Get conversations for a specific user
  Stream<List<Conversation>> getConversationsForUser(String userId, UserRole role) {
    if (!_isFirebaseMode) {
      // Demo mode - return local data as stream
      final filtered = _conversations.where((conv) {
        if (role == UserRole.user) {
          return conv.userId == userId;
        } else if (role == UserRole.counselor) {
          return conv.counselorId == userId;
        } else if (role == UserRole.admin) {
          return true;
        }
        return false;
      }).toList();
      return Stream.value(filtered);
    }

    // Firebase mode
    Query query = _firestore.collection('conversations');
    
    if (role == UserRole.user) {
      query = query.where('userId', isEqualTo: userId);
    } else if (role == UserRole.counselor) {
      query = query.where('counselorId', isEqualTo: userId);
    }
    // Admin sees all conversations (no filter)

    return query.snapshots().asyncMap((snapshot) async {
      List<Conversation> conversations = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get the last message for this conversation
        final messagesSnapshot = await _firestore
            .collection('conversations')
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        
        Message? lastMessage;
        MessagePriority highestPriority = MessagePriority.low;
        
        if (messagesSnapshot.docs.isNotEmpty) {
          final messageData = messagesSnapshot.docs.first.data();
          
          // Debug: Print the emoji data
          debugPrint('📱 Message aiEmojis from Firestore: ${messageData['aiEmojis']}');
          
          lastMessage = Message(
            id: messagesSnapshot.docs.first.id,
            senderId: messageData['senderId'] ?? '',
            receiverId: messageData['receiverId'] ?? '',
            content: messageData['content'] ?? '',
            priority: _parseMessagePriority(messageData['priority']),
            timestamp: (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: _parseMessageStatus(messageData['status']),
            replyToId: messageData['replyToId'],
            aiEmojis: List<String>.from(messageData['aiEmojis'] ?? []),
            urgencyScore: (messageData['urgencyScore'] ?? 0.0).toDouble(),
          );
          highestPriority = lastMessage.priority;
          
          // Debug: Confirm emoji was parsed
          debugPrint('✅ Message created with emojis: ${lastMessage.aiEmojis}');
        }
        
        // Handle null lastActivity from FieldValue.serverTimestamp()
        DateTime lastActivity;
        if (data['lastActivity'] != null) {
          lastActivity = (data['lastActivity'] as Timestamp).toDate();
        } else {
          lastActivity = DateTime.now();
        }
        
        // Handle null lastMessageStatus
        MessageStatus lastMessageStatus;
        if (data['lastMessageStatus'] != null) {
          lastMessageStatus = _parseMessageStatus(data['lastMessageStatus']);
        } else {
          lastMessageStatus = MessageStatus.sent;
        }
        
        conversations.add(Conversation(
          id: doc.id,
          userId: data['userId'] ?? '',
          counselorId: data['counselorId'] ?? '',
          messages: lastMessage != null ? [lastMessage] : [],
          lastActivity: lastActivity,
          lastMessageStatus: lastMessageStatus,
          isActive: data['isActive'] ?? true,
        ));
      }
      
      return conversations;
    });
  }

  // Get messages for a specific conversation
  Stream<List<Message>> getMessagesForConversation(String conversationId) {
    if (!_isFirebaseMode) {
      // Demo mode
      try {
        final conversation = _conversations.firstWhere(
          (conv) => conv.id == conversationId,
          orElse: () => throw Exception('Conversation not found'),
        );
        return Stream.value(List.from(conversation.messages));
      } catch (e) {
        return Stream.value([]);
      }
    }

    // Firebase mode
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          receiverId: data['receiverId'] ?? '',
          content: data['content'] ?? '',
          priority: _parseMessagePriority(data['priority']),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          status: _parseMessageStatus(data['status']),
          replyToId: data['replyToId'],
          aiEmojis: List<String>.from(data['aiEmojis'] ?? []),
          urgencyScore: (data['urgencyScore'] ?? 0.0).toDouble(),
        );
      }).toList();
    });
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
      
      final messageData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'priority': analysis.priority.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'status': MessageStatus.sent.toString().split('.').last,
        'replyToId': replyToId,
        'aiEmojis': analysis.suggestedEmojis,
        'urgencyScore': analysis.urgencyScore,
      };

      if (!_isFirebaseMode) {
        // Demo mode - keep existing logic
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

        if (!_conversations.contains(conversation)) {
          _conversations.add(conversation);
        }

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

        final conversationIndex = _conversations.indexWhere((c) => c.id == conversation.id);
        _conversations[conversationIndex] = updatedConversation;
        _allMessages.add(message);
        _sortConversationsByPriority();
        notifyListeners();
        return true;
      }

      // Firebase mode
      // Determine userId and counselorId properly
      String conversationUserId;
      String conversationCounselorId;

      // Fetch sender and receiver roles
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      
      final senderRole = senderDoc.data()?['role'] ?? 'user';
      final receiverRole = receiverDoc.data()?['role'] ?? 'user';

      // The regular user should always be userId, counselor should be counselorId
      if (senderRole == 'user') {
        conversationUserId = senderId;
        conversationCounselorId = receiverId;
      } else if (receiverRole == 'user') {
        conversationUserId = receiverId;
        conversationCounselorId = senderId;
      } else {
        // Both are counselors or admins - use alphabetical order
        if (senderId.compareTo(receiverId) < 0) {
          conversationUserId = senderId;
          conversationCounselorId = receiverId;
        } else {
          conversationUserId = receiverId;
          conversationCounselorId = senderId;
        }
      }

      // Find or create conversation
      final conversationQuery = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: conversationUserId)
          .where('counselorId', isEqualTo: conversationCounselorId)
          .limit(1)
          .get();

      String conversationId;
      
      if (conversationQuery.docs.isEmpty) {
        // Create new conversation
        final conversationData = {
          'userId': conversationUserId,
          'counselorId': conversationCounselorId,
          'lastActivity': FieldValue.serverTimestamp(),
          'lastMessageStatus': MessageStatus.sent.toString().split('.').last,
          'isActive': true,
          'highestPriority': analysis.priority.toString().split('.').last,
        };
        
        final conversationRef = await _firestore.collection('conversations').add(conversationData);
        conversationId = conversationRef.id;
      } else {
        conversationId = conversationQuery.docs.first.id;
        
        // Update conversation
        await _firestore.collection('conversations').doc(conversationId).update({
          'lastActivity': FieldValue.serverTimestamp(),
          'lastMessageStatus': MessageStatus.sent.toString().split('.').last,
        });
      }

      // Add message to conversation
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      debugPrint('✅ Message sent successfully to Firestore');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
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
      debugPrint('Error marking message as read: $e');
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

  MessagePriority _parseMessagePriority(String? priority) {
    switch (priority) {
      case 'critical':
        return MessagePriority.critical;
      case 'urgent':
        return MessagePriority.urgent;
      case 'high':
        return MessagePriority.high;
      case 'low':
        return MessagePriority.low;
      default:
        return MessagePriority.normal;
    }
  }

  // Helper method to parse message status from string
  MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'replied':
        return MessageStatus.replied;
      default:
        return MessageStatus.sent;
    }
  }
}