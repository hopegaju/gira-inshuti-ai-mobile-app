import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../models/user.dart';
import '../models/message.dart';
import 'chat_screen.dart';

class MessagingScreen extends StatelessWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
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
                    margin: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 12,
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
            return const Center(child: Text('Please log in to access messages'));
          }

          final conversations = messagingService.getConversationsForUser(
            currentUser.id,
            currentUser.role,
          );

          return Column(
            children: [
              // Quick actions for users
              if (currentUser.role == UserRole.user) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect with a Counselor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: StreamBuilder<List<User>>(
                          stream: authService.getAllCounselors(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  'No counselors available',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              );
                            }

                            final counselors = snapshot.data!;
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: counselors.length,
                              itemBuilder: (context, index) {
                                final counselor = counselors[index];
                                return _buildCounselorCard(
                                  context,
                                  counselor,
                                  currentUser,
                                  messagingService,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // Conversations list
              Expanded(
                child: conversations.isEmpty
                    ? _buildEmptyState(currentUser.role)
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final otherUser = _getOtherUser(conversation, currentUser, authService);
                          
                          return _buildConversationTile(
                            context,
                            conversation,
                            otherUser,
                            currentUser,
                            messagingService,
                          );
                        },
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
  ) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                otherUser: counselor,
                conversationId: messagingService
                    .getConversationBetweenUsers(currentUser.id, counselor.id)?.id,
              ),
            ),
          );
        },
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              radius: 25,
              child: Text(
                counselor.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              counselor.name.split(' ').first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Online',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
            child: Text(
              otherUser?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: _getUserColor(otherUser?.role),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Priority indicator for counselors
          if (currentUser.role == UserRole.counselor && 
              conversation.highestPriority.level >= MessagePriority.high.level)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getPriorityColor(conversation.highestPriority),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    conversation.highestPriority.emoji,
                    style: const TextStyle(fontSize: 8),
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
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (lastMessage != null) ...[
            // AI emojis for last message (visible to counselors only)
            if (currentUser.role == UserRole.counselor && lastMessage.aiEmojis.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 4),
                child: Text(
                  lastMessage.aiEmojis.take(2).join(''),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              _formatTime(lastMessage.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      subtitle: lastMessage != null
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    lastMessage.content,
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.grey.shade800 : Colors.grey.shade600,
                      fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            )
          : Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey.shade500),
            ),
      isThreeLine: false,
    );
  }

  Widget _buildEmptyState(UserRole role) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role == UserRole.user ? Icons.chat_bubble_outline : Icons.psychology,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              role == UserRole.user
                  ? 'No conversations yet'
                  : 'No client messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              role == UserRole.user
                  ? 'Tap on a counselor above to start a conversation'
                  : 'Conversations will appear here when users message you',
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

  User? _getOtherUser(Conversation conversation, User currentUser, AuthService authService) {
    final otherUserId = currentUser.id == conversation.userId 
        ? conversation.counselorId 
        : conversation.userId;
    
    // Since getUserById doesn't exist in AuthService, we need to get users from the stream
    // For now, we'll return null and handle it in the UI, or you need to add getUserById to AuthService
    // This is a temporary workaround - you should add getUserById method to AuthService
    return null; // TODO: Implement getUserById in AuthService or fetch from a local cache
  }

  Color _getUserColor(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.counselor:
        return Colors.green;
      case UserRole.user:
        return Colors.blue;
      default:
        return Colors.grey;
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
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}