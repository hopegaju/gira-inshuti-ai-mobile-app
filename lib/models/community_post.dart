// models/community_post.dart
enum PostCategory {
  general,
  support,
  advice,
  motivation,
  story,
}

extension PostCategoryExtension on PostCategory {
  String get displayName {
    switch (this) {
      case PostCategory.general:
        return 'General';
      case PostCategory.support:
        return 'Support';
      case PostCategory.advice:
        return 'Advice';
      case PostCategory.motivation:
        return 'Motivation';
      case PostCategory.story:
        return 'Story';
    }
  }
}

enum ReactionType {
  support,
  helpful,
  inspiring,
}

enum ContentSeverityLevel {
  mild,      // General discussions, light concerns
  moderate,  // Some emotional distress but manageable
  severe,    // High emotional distress, concerning content
  critical,  // Self-harm, suicidal content - requires immediate attention
}

class CommunityReply {
  final String id;
  final String userId;  // For internal tracking, not displayed
  final String content;
  final DateTime timestamp;
  final ContentSeverityLevel severityLevel;

  CommunityReply({
    required this.id,
    required this.userId,
    required this.content,
    required this.timestamp,
    required this.severityLevel,
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    return CommunityReply(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      severityLevel: ContentSeverityLevel.values.firstWhere(
        (level) => level.name == json['severityLevel'],
        orElse: () => ContentSeverityLevel.mild,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'severityLevel': severityLevel.name,
    };
  }
}

class CommunityPost {
  final String id;
  final String userId;  // For internal tracking, not displayed to maintain anonymity
  final String content;
  final PostCategory category;
  final DateTime timestamp;
  final Map<String, ReactionType> reactions; // userId -> reaction type
  final List<CommunityReply> replies;
  final ContentSeverityLevel severityLevel;
  final List<String> triggerWarnings;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.content,
    required this.category,
    required this.timestamp,
    this.reactions = const {},
    this.replies = const [],
    required this.severityLevel,
    this.triggerWarnings = const [],
  });

  // Computed properties
  int get supportCount => reactions.values.where((r) => r == ReactionType.support).length;
  int get helpfulCount => reactions.values.where((r) => r == ReactionType.helpful).length;
  int get inspiringCount => reactions.values.where((r) => r == ReactionType.inspiring).length;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      category: PostCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => PostCategory.general,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      reactions: Map<String, ReactionType>.from(
        json['reactions']?.map((key, value) => MapEntry(
          key,
          ReactionType.values.firstWhere((r) => r.name == value),
        )) ?? {},
      ),
      replies: (json['replies'] as List?)
          ?.map((reply) => CommunityReply.fromJson(reply))
          .toList() ?? [],
      severityLevel: ContentSeverityLevel.values.firstWhere(
        (level) => level.name == json['severityLevel'],
        orElse: () => ContentSeverityLevel.mild,
      ),
      triggerWarnings: List<String>.from(json['triggerWarnings'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'reactions': reactions.map((key, value) => MapEntry(key, value.name)),
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'severityLevel': severityLevel.name,
      'triggerWarnings': triggerWarnings,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? content,
    PostCategory? category,
    DateTime? timestamp,
    Map<String, ReactionType>? reactions,
    List<CommunityReply>? replies,
    ContentSeverityLevel? severityLevel,
    List<String>? triggerWarnings,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replies: replies ?? this.replies,
      severityLevel: severityLevel ?? this.severityLevel,
      triggerWarnings: triggerWarnings ?? this.triggerWarnings,
    );
  }
}

// User preference model for content filtering
class UserContentPreferences {
  final String userId;
  final ContentSeverityLevel maxSeverityLevel;
  final List<String> blockedTriggerWarnings;
  final bool showSupportivePosts;
  final bool showAdvicePosts;
  final bool showMotivationalPosts;
  final bool showStoryPosts;

  UserContentPreferences({
    required this.userId,
    this.maxSeverityLevel = ContentSeverityLevel.moderate,
    this.blockedTriggerWarnings = const [],
    this.showSupportivePosts = true,
    this.showAdvicePosts = true,
    this.showMotivationalPosts = true,
    this.showStoryPosts = true,
  });

  factory UserContentPreferences.fromJson(Map<String, dynamic> json) {
    return UserContentPreferences(
      userId: json['userId'],
      maxSeverityLevel: ContentSeverityLevel.values.firstWhere(
        (level) => level.name == json['maxSeverityLevel'],
        orElse: () => ContentSeverityLevel.moderate,
      ),
      blockedTriggerWarnings: List<String>.from(json['blockedTriggerWarnings'] ?? []),
      showSupportivePosts: json['showSupportivePosts'] ?? true,
      showAdvicePosts: json['showAdvicePosts'] ?? true,
      showMotivationalPosts: json['showMotivationalPosts'] ?? true,
      showStoryPosts: json['showStoryPosts'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'maxSeverityLevel': maxSeverityLevel.name,
      'blockedTriggerWarnings': blockedTriggerWarnings,
      'showSupportivePosts': showSupportivePosts,
      'showAdvicePosts': showAdvicePosts,
      'showMotivationalPosts': showMotivationalPosts,
      'showStoryPosts': showStoryPosts,
    };
  }

  UserContentPreferences copyWith({
    String? userId,
    ContentSeverityLevel? maxSeverityLevel,
    List<String>? blockedTriggerWarnings,
    bool? showSupportivePosts,
    bool? showAdvicePosts,
    bool? showMotivationalPosts,
    bool? showStoryPosts,
  }) {
    return UserContentPreferences(
      userId: userId ?? this.userId,
      maxSeverityLevel: maxSeverityLevel ?? this.maxSeverityLevel,
      blockedTriggerWarnings: blockedTriggerWarnings ?? this.blockedTriggerWarnings,
      showSupportivePosts: showSupportivePosts ?? this.showSupportivePosts,
      showAdvicePosts: showAdvicePosts ?? this.showAdvicePosts,
      showMotivationalPosts: showMotivationalPosts ?? this.showMotivationalPosts,
      showStoryPosts: showStoryPosts ?? this.showStoryPosts,
    );
  }
}