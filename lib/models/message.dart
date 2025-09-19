// models/message.dart
import 'package:flutter/foundation.dart';

enum MessagePriority { 
  low(1), 
  normal(2), 
  high(3), 
  urgent(4), 
  critical(5);
  
  const MessagePriority(this.level);
  final int level;
  
  String get displayName {
    switch (this) {
      case MessagePriority.low:
        return 'Low';
      case MessagePriority.normal:
        return 'Normal';
      case MessagePriority.high:
        return 'High';
      case MessagePriority.urgent:
        return 'Urgent';
      case MessagePriority.critical:
        return 'Critical';
    }
  }
  
  String get emoji {
    switch (this) {
      case MessagePriority.low:
        return '💬';
      case MessagePriority.normal:
        return '📝';
      case MessagePriority.high:
        return '⚠️';
      case MessagePriority.urgent:
        return '🚨';
      case MessagePriority.critical:
        return '🆘';
    }
  }
}

enum MessageStatus {
  sent,
  delivered,
  read,
  replied
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessagePriority priority;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToId;
  final List<String> aiEmojis;
  final double urgencyScore; // Internal score (0.0 - 1.0)
  
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.priority,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyToId,
    this.aiEmojis = const [],
    this.urgencyScore = 0.0,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      priority: MessagePriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => MessagePriority.normal,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      replyToId: json['replyToId'],
      aiEmojis: List<String>.from(json['aiEmojis'] ?? []),
      urgencyScore: (json['urgencyScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'priority': priority.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'replyToId': replyToId,
      'aiEmojis': aiEmojis,
      'urgencyScore': urgencyScore,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessagePriority? priority,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToId,
    List<String>? aiEmojis,
    double? urgencyScore,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      aiEmojis: aiEmojis ?? this.aiEmojis,
      urgencyScore: urgencyScore ?? this.urgencyScore,
    );
  }
}

class Conversation {
  final String id;
  final String userId;
  final String counselorId;
  final List<Message> messages;
  final DateTime lastActivity;
  final MessageStatus lastMessageStatus;
  final bool isActive;

  Conversation({
    required this.id,
    required this.userId,
    required this.counselorId,
    required this.messages,
    required this.lastActivity,
    required this.lastMessageStatus,
    this.isActive = true,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['userId'],
      counselorId: json['counselorId'],
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
      lastActivity: DateTime.parse(json['lastActivity']),
      lastMessageStatus: MessageStatus.values.firstWhere(
        (s) => s.name == json['lastMessageStatus'],
        orElse: () => MessageStatus.sent,
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'counselorId': counselorId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastActivity': lastActivity.toIso8601String(),
      'lastMessageStatus': lastMessageStatus.name,
      'isActive': isActive,
    };
  }

  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;
  
  MessagePriority get highestPriority {
    if (messages.isEmpty) return MessagePriority.normal;
    return messages
        .where((m) => m.status != MessageStatus.replied)
        .map((m) => m.priority)
        .fold(MessagePriority.low, (prev, curr) => 
            curr.level > prev.level ? curr : prev);
  }
}