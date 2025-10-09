import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../screens/chat_screen.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  _MessagesTabState createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<MessagingService>(
            builder: (context, messagingService, child) {
              final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
              final unreadCount = messagingService.getUnreadCount(
                currentUser?.id ?? '', 
                currentUser?.role ?? UserRole.user
              );
              
              return unreadCount > 0
                ? Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<AuthService, MessagingService>(
        builder: (context, authService, messagingService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Please log in to access messages',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final conversations = messagingService.getConversationsForUser(
            currentUser.id,
            currentUser.role,
          );

          return Column(
            children: [
              // Counselors Section - Only for regular users
              if (currentUser.role == UserRole.user)
                StreamBuilder<List<User>>(
                  stream: authService.getAllCounselors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            'No counselors available at the moment',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }

                    final counselors = snapshot.data!.take(10).toList();
                    
                    return Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Available Counselors',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${counselors.length} online',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 110,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: counselors.length,
                              itemBuilder: (context, index) {
                                final counselor = counselors[index];
                                final existingConversation = messagingService
                                    .getConversationBetweenUsers(
                                      currentUser.id, 
                                      counselor.id
                                    );
                                
                                return _buildCounselorCard(
                                  context,
                                  counselor,
                                  currentUser,
                                  messagingService,
                                  existingConversation,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              
              // Divider
              if (currentUser.role == UserRole.user)
                Container(
                  height: 8,
                  color: Colors.grey.shade100,
                ),
              
              // Conversations Header
              if (conversations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentUser.role == UserRole.counselor 
                          ? 'Client Conversations'
                          : 'Your Conversations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Conversations List
              Expanded(
                child: conversations.isEmpty
                    ? _buildEmptyState(currentUser.role)
                    : Container(
                        color: Colors.white,
                        child: ListView.separated(
                          itemCount: conversations.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 72,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return StreamBuilder<List<User>>(
                              stream: authService.getAllUsers(),
                              builder: (context, userSnapshot) {
                                final otherUserId = currentUser.id == conversation.userId 
                                    ? conversation.counselorId 
                                    : conversation.userId;
                                
                                User? otherUser;
                                if (userSnapshot.hasData) {
                                  otherUser = userSnapshot.data!.firstWhere(
                                    (u) => u.id == otherUserId,
                                    orElse: () => User(
                                      id: otherUserId,
                                      email: 'unknown@example.com',
                                      name: 'Unknown User',
                                      role: UserRole.user,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                }
                                
                                return _buildConversationTile(
                                  context,
                                  conversation,
                                  otherUser,
                                  currentUser,
                                  messagingService,
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCounselorCard(
    BuildContext context,
    User counselor,
    User currentUser,
    MessagingService messagingService,
    Conversation? existingConversation,
  ) {
    final hasUnread = existingConversation != null &&
        existingConversation.messages.any(
          (m) => m.receiverId == currentUser.id && m.status != MessageStatus.read
        );

    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  otherUser: counselor,
                  conversationId: existingConversation?.id,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasUnread ? Colors.green.shade400 : Colors.green.shade100,
                width: hasUnread ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      radius: 24,
                      child: Text(
                        counselor.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  counselor.name.split(' ').first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    User? otherUser,
    User currentUser,
    MessagingService messagingService,
  ) {
    final lastMessage = conversation.lastMessage;
    final unreadCount = conversation.messages
        .where((m) => m.receiverId == currentUser.id && m.status != MessageStatus.read)
        .length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        if (otherUser != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUser: otherUser,
                conversationId: conversation.id,
              ),
            ),
          );
        }
      },
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: _getUserColor(otherUser?.role).withOpacity(0.1),
            radius: 28,
            child: Text(
              otherUser?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: _getUserColor(otherUser?.role),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (currentUser.role == UserRole.counselor && 
              conversation.highestPriority.level >= MessagePriority.high.level)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _getPriorityColor(conversation.highestPriority),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.priority_high,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser?.name ?? 'Unknown User',
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (lastMessage != null)
            Text(
              _formatTime(lastMessage.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? Colors.blue.shade600 : Colors.grey.shade600,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (lastMessage != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    lastMessage.content,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.grey.shade800 : Colors.grey.shade600,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          if (currentUser.role == UserRole.counselor && 
              lastMessage != null && 
              lastMessage.aiEmojis.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lastMessage.aiEmojis.take(3).join(' '),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
    );
  }

  Widget _buildEmptyState(UserRole role) {
    final isUser = role == UserRole.user;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade50 : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUser ? Icons.favorite_outline : Icons.psychology_outlined,
                size: 60,
                color: isUser ? Colors.blue.shade400 : Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isUser 
                ? 'Pour Your Heart Out' 
                : 'Ready to Support',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isUser
                ? 'This is your safe space. Choose a counselor above to start a confidential conversation. They\'re here to listen, support, and guide you.'
                : 'Your clients will appear here when they reach out. Be ready to provide compassionate support and guidance.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isUser) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_objects_outlined,
                      color: Colors.amber.shade700,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Remember',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every conversation is completely confidential. Our counselors are here to help you navigate life\'s challenges with empathy and understanding.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade800,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUserColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red.shade700;
      case UserRole.counselor:
        return Colors.green.shade700;
      case UserRole.user:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}