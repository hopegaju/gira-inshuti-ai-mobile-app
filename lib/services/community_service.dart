// services/community_service.dart
import 'package:flutter/foundation.dart';
import '../models/community_post.dart';

class CommunityService extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  final Map<String, UserContentPreferences> _userPreferences = {};

  List<CommunityPost> get allPosts => List.from(_posts);

  // Content analysis keywords for severity detection
  static const Map<ContentSeverityLevel, List<String>> _severityKeywords = {
    ContentSeverityLevel.critical: [
      'suicide', 'kill myself', 'end it all', 'want to die', 'overdose',
      'self-harm', 'hurt myself', 'cutting', 'razor', 'pills to die',
      'jump off', 'hang myself', 'gun', 'blade', 'poison'
    ],
    ContentSeverityLevel.severe: [
      'hopeless', 'worthless', 'can\'t go on', 'nobody cares', 'hate myself',
      'breakdown', 'panic attack', 'can\'t breathe', 'losing control',
      'desperate', 'terrified', 'nightmares', 'flashbacks', 'trauma'
    ],
    ContentSeverityLevel.moderate: [
      'depressed', 'anxious', 'stressed', 'worried', 'sad', 'lonely',
      'overwhelmed', 'tired', 'confused', 'angry', 'frustrated',
      'relationship problems', 'family issues', 'work stress'
    ],
    ContentSeverityLevel.mild: [
      'advice', 'support', 'help', 'guidance', 'question', 'wondering',
      'thinking', 'grateful', 'thankful', 'motivated', 'inspired'
    ],
  };

  static const List<String> _commonTriggerWarnings = [
    'self-harm', 'suicide', 'eating disorders', 'substance abuse',
    'domestic violence', 'sexual assault', 'child abuse', 'trauma',
    'death', 'grief', 'panic attacks', 'depression'
  ];

  CommunityService() {
    _initializeDemoData();
  }

  // Analyze content and determine severity level
  ContentSeverityLevel _analyzeContentSeverity(String content) {
    final cleanContent = content.toLowerCase().trim();
    
    // Check for critical content first
    for (final keyword in _severityKeywords[ContentSeverityLevel.critical]!) {
      if (cleanContent.contains(keyword)) {
        return ContentSeverityLevel.critical;
      }
    }
    
    // Check for severe content
    for (final keyword in _severityKeywords[ContentSeverityLevel.severe]!) {
      if (cleanContent.contains(keyword)) {
        return ContentSeverityLevel.severe;
      }
    }
    
    // Check for moderate content
    for (final keyword in _severityKeywords[ContentSeverityLevel.moderate]!) {
      if (cleanContent.contains(keyword)) {
        return ContentSeverityLevel.moderate;
      }
    }
    
    return ContentSeverityLevel.mild;
  }

  // Detect trigger warnings in content
  List<String> _detectTriggerWarnings(String content) {
    final cleanContent = content.toLowerCase();
    List<String> triggers = [];
    
    for (final trigger in _commonTriggerWarnings) {
      if (cleanContent.contains(trigger) || cleanContent.contains(trigger.replaceAll(' ', ''))) {
        triggers.add(trigger);
      }
    }
    
    return triggers;
  }

  // Auto-categorize post based on content
  PostCategory _categorizePost(String content) {
    final cleanContent = content.toLowerCase();
    
    if (cleanContent.contains(RegExp(r'\b(advice|help|question|how|should|what)\b'))) {
      return PostCategory.advice;
    } else if (cleanContent.contains(RegExp(r'\b(support|lonely|need|struggling|difficult)\b'))) {
      return PostCategory.support;
    } else if (cleanContent.contains(RegExp(r'\b(motivated|inspired|grateful|positive|hope|strength)\b'))) {
      return PostCategory.motivation;
    } else if (cleanContent.contains(RegExp(r'\b(story|experience|happened|when|remember)\b'))) {
      return PostCategory.story;
    }
    
    return PostCategory.general;
  }

  // Create a new post
  Future<bool> createPost({
    required String userId,
    required String content,
    PostCategory? category,
  }) async {
    try {
      final severityLevel = _analyzeContentSeverity(content);
      final triggerWarnings = _detectTriggerWarnings(content);
      final autoCategory = category ?? _categorizePost(content);

      // For critical content, we might want to alert moderators or counselors
      if (severityLevel == ContentSeverityLevel.critical) {
        _alertModerators(userId, content);
      }

      final post = CommunityPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        content: content,
        category: autoCategory,
        timestamp: DateTime.now(),
        severityLevel: severityLevel,
        triggerWarnings: triggerWarnings,
      );

      _posts.insert(0, post); // Add to beginning for newest first
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return false;
    }
  }

  // Reply to a post
  Future<bool> replyToPost(String postId, String userId, String content) async {
    try {
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex == -1) return false;

      final severityLevel = _analyzeContentSeverity(content);
      
      final reply = CommunityReply(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        content: content,
        timestamp: DateTime.now(),
        severityLevel: severityLevel,
      );

      final post = _posts[postIndex];
      final updatedReplies = List<CommunityReply>.from(post.replies)..add(reply);
      
      _posts[postIndex] = post.copyWith(replies: updatedReplies);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error replying to post: $e');
      return false;
    }
  }

  // Toggle reaction on a post
  void toggleReaction(String postId, String userId, ReactionType reactionType) {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final reactions = Map<String, ReactionType>.from(post.reactions);

    if (reactions.containsKey(userId) && reactions[userId] == reactionType) {
      reactions.remove(userId); // Remove if same reaction
    } else {
      reactions[userId] = reactionType; // Add or change reaction
    }

    _posts[postIndex] = post.copyWith(reactions: reactions);
    notifyListeners();
  }

  // Get filtered posts based on user preferences and filter
  List<CommunityPost> getFilteredPosts(String filter, [String? userId]) {
    List<CommunityPost> filteredPosts = _posts;

    // Apply user's content preferences if userId provided
    if (userId != null && _userPreferences.containsKey(userId)) {
      filteredPosts = _filterByUserPreferences(filteredPosts, userId);
    } else {
      // Default filtering for users without preferences - hide critical content
      filteredPosts = filteredPosts
          .where((post) => post.severityLevel != ContentSeverityLevel.critical)
          .toList();
    }

    // Apply category filter
    switch (filter) {
      case 'Support':
        filteredPosts = filteredPosts
            .where((post) => post.category == PostCategory.support)
            .toList();
        break;
      case 'Advice':
        filteredPosts = filteredPosts
            .where((post) => post.category == PostCategory.advice)
            .toList();
        break;
      case 'Motivation':
        filteredPosts = filteredPosts
            .where((post) => post.category == PostCategory.motivation)
            .toList();
        break;
      case 'Stories':
        filteredPosts = filteredPosts
            .where((post) => post.category == PostCategory.story)
            .toList();
        break;
      default: // 'All'
        break;
    }

    return filteredPosts;
  }

  // Check if user can view a specific post
  bool canUserViewPost(CommunityPost post, String userId) {
    if (_userPreferences.containsKey(userId)) {
      final prefs = _userPreferences[userId]!;
      
      // Check severity level
      if (post.severityLevel.index > prefs.maxSeverityLevel.index) {
        return false;
      }
      
      // Check trigger warnings
      for (final trigger in post.triggerWarnings) {
        if (prefs.blockedTriggerWarnings.contains(trigger)) {
          return false;
        }
      }
      
      // Check category preferences
      switch (post.category) {
        case PostCategory.support:
          return prefs.showSupportivePosts;
        case PostCategory.advice:
          return prefs.showAdvicePosts;
        case PostCategory.motivation:
          return prefs.showMotivationalPosts;
        case PostCategory.story:
          return prefs.showStoryPosts;
        default:
          return true;
      }
    }
    
    // Default: hide critical content for users without preferences
    return post.severityLevel != ContentSeverityLevel.critical;
  }

  // Filter posts by user preferences
  List<CommunityPost> _filterByUserPreferences(List<CommunityPost> posts, String userId) {
    final prefs = _userPreferences[userId];
    if (prefs == null) return posts;

    return posts.where((post) => canUserViewPost(post, userId)).toList();
  }

  // Update user content preferences
  void updateUserPreferences(String userId, UserContentPreferences preferences) {
    _userPreferences[userId] = preferences;
    notifyListeners();
  }

  // Get user preferences or create default
  UserContentPreferences getUserPreferences(String userId) {
    return _userPreferences[userId] ?? UserContentPreferences(userId: userId);
  }

  // Alert moderators for critical content (placeholder)
  void _alertModerators(String userId, String content) {
    // In a real app, this would:
    // 1. Notify counselors/moderators
    // 2. Possibly create priority message to counselor
    // 3. Log for review
    // 4. Potentially provide crisis resources to user
    debugPrint('ALERT: Critical content detected from user $userId');
  }

  // Search posts
  List<CommunityPost> searchPosts(String query, String userId) {
    final filteredPosts = getFilteredPosts('All', userId);
    
    return filteredPosts
        .where((post) => 
          post.content.toLowerCase().contains(query.toLowerCase()) ||
          post.replies.any((reply) => 
            reply.content.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  // Get posts by category
  List<CommunityPost> getPostsByCategory(PostCategory category, String userId) {
    return getFilteredPosts('All', userId)
        .where((post) => post.category == category)
        .toList();
  }

  // Initialize with demo data
  void _initializeDemoData() {
    final demoPosts = [
      CommunityPost(
        id: 'demo_1',
        userId: 'user_demo_1',
        content: 'I\'ve been feeling really anxious about starting college next month. Any advice on how to manage the transition?',
        category: PostCategory.advice,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        severityLevel: ContentSeverityLevel.moderate,
        triggerWarnings: [],
        reactions: {
          'user_2': ReactionType.support,
          'user_3': ReactionType.helpful,
        },
        replies: [
          CommunityReply(
            id: 'reply_1',
            userId: 'user_demo_2',
            content: 'I felt the same way! What helped me was visiting the campus beforehand and joining online groups for incoming students.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            severityLevel: ContentSeverityLevel.mild,
          ),
        ],
      ),
      CommunityPost(
        id: 'demo_2',
        userId: 'user_demo_2',
        content: 'Just wanted to share that after months of therapy, I finally feel like I\'m making progress. Don\'t give up hope!',
        category: PostCategory.motivation,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        severityLevel: ContentSeverityLevel.mild,
        reactions: {
          'user_1': ReactionType.inspiring,
          'user_4': ReactionType.support,
          'user_5': ReactionType.inspiring,
        },
      ),
      CommunityPost(
        id: 'demo_3',
        userId: 'user_demo_3',
        content: 'Having a really tough day with depression. Everything feels overwhelming and I don\'t know how to cope.',
        category: PostCategory.support,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        severityLevel: ContentSeverityLevel.severe,
        triggerWarnings: ['depression'],
        reactions: {
          'user_6': ReactionType.support,
        },
        replies: [
          CommunityReply(
            id: 'reply_2',
            userId: 'user_demo_4',
            content: 'You\'re not alone. Have you tried reaching out to a counselor or trusted friend today?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            severityLevel: ContentSeverityLevel.mild,
          ),
        ],
      ),
    ];

    _posts = demoPosts;

    // Demo user preferences
    _userPreferences['demo_user_safe'] = UserContentPreferences(
      userId: 'demo_user_safe',
      maxSeverityLevel: ContentSeverityLevel.moderate,
      blockedTriggerWarnings: ['self-harm', 'suicide'],
    );
  }

  // Clear all data (for testing)
  void clearAllData() {
    _posts.clear();
    _userPreferences.clear();
    notifyListeners();
  }
}