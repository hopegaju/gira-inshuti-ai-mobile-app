// services/ai_priority_service.dart
import '../models/message.dart';

class AIPriorityService {
  // Keywords and phrases for different priority levels
  static const Map<MessagePriority, List<String>> _priorityKeywords = {
    MessagePriority.critical: [
      'suicide', 'kill myself', 'end it all', 'can\'t go on', 'want to die',
      'self-harm', 'hurt myself', 'overdose', 'emergency', 'crisis',
      'dangerous', 'life threatening', 'immediate help', 'urgent care'
    ],
    MessagePriority.urgent: [
      'panic', 'anxiety attack', 'breakdown', 'can\'t breathe', 'overwhelmed',
      'desperate', 'scared', 'terrified', 'losing control', 'help me',
      'right now', 'immediately', 'urgent', 'emergency', 'crisis mode'
    ],
    MessagePriority.high: [
      'depressed', 'depression', 'sad all the time', 'hopeless', 'worthless',
      'anxious', 'stressed', 'worried sick', 'can\'t sleep', 'nightmares',
      'relationship problems', 'family issues', 'work stress', 'financial trouble'
    ],
    MessagePriority.normal: [
      'advice', 'guidance', 'talk about', 'discuss', 'wondering',
      'thinking about', 'question', 'help with', 'support', 'suggestion'
    ],
    MessagePriority.low: [
      'hello', 'hi', 'good morning', 'how are you', 'check in',
      'just saying', 'casual', 'thanks', 'appreciate', 'gratitude'
    ],
  };

  // Emotional indicators that boost priority
  static const Map<String, double> _emotionWeights = {
    // High intensity emotions
    'desperate': 0.8,
    'terrified': 0.9,
    'panicking': 0.9,
    'hopeless': 0.7,
    'worthless': 0.6,
    'overwhelmed': 0.6,
    'scared': 0.5,
    'worried': 0.4,
    'anxious': 0.5,
    'depressed': 0.6,
    'sad': 0.3,
    'stressed': 0.4,
    'confused': 0.2,
    'tired': 0.1,
  };

  // Urgency indicators
  static const List<String> _urgencyIndicators = [
    'now', 'immediately', 'urgent', 'asap', 'right now', 'emergency',
    'can\'t wait', 'need help', 'please help', 'help me'
  ];

  // Question types that might need immediate attention
  static const List<String> _concerningQuestions = [
    'what should i do', 'how do i', 'is it normal', 'am i',
    'should i be worried', 'is this bad', 'help me understand'
  ];

  static MessageAnalysis analyzeMessage(String content) {
    final cleanContent = content.toLowerCase().trim();
    
    double urgencyScore = 0.0;
    MessagePriority priority = MessagePriority.normal;
    List<String> suggestedEmojis = [];
    List<String> detectedConcerns = [];

    // 1. Check for priority keywords
    for (final entry in _priorityKeywords.entries) {
      for (final keyword in entry.value) {
        if (cleanContent.contains(keyword.toLowerCase())) {
          priority = _getBestPriority(priority, entry.key);
          urgencyScore += entry.key.level * 0.1;
          detectedConcerns.add(keyword);
        }
      }
    }

    // 2. Analyze emotional intensity
    for (final entry in _emotionWeights.entries) {
      if (cleanContent.contains(entry.key)) {
        urgencyScore += entry.value;
        detectedConcerns.add(entry.key);
      }
    }

    // 3. Check urgency indicators
    for (final indicator in _urgencyIndicators) {
      if (cleanContent.contains(indicator)) {
        urgencyScore += 0.3;
        priority = _getBestPriority(priority, MessagePriority.high);
      }
    }

    // 4. Analyze sentence structure for desperation
    if (cleanContent.contains('!')) {
      final exclamationCount = '!'.allMatches(cleanContent).length;
      urgencyScore += exclamationCount * 0.1;
    }

    // Multiple question marks indicate confusion/desperation
    if (cleanContent.contains('??')) {
      urgencyScore += 0.2;
    }

    // ALL CAPS indicates urgency
    if (content.toUpperCase() == content && content.length > 10) {
      urgencyScore += 0.4;
      priority = _getBestPriority(priority, MessagePriority.high);
    }

    // 5. Check for concerning questions
    for (final question in _concerningQuestions) {
      if (cleanContent.contains(question)) {
        urgencyScore += 0.2;
        priority = _getBestPriority(priority, MessagePriority.normal);
      }
    }

    // 6. Normalize urgency score
    urgencyScore = urgencyScore.clamp(0.0, 1.0);

    // 7. Adjust priority based on final urgency score
    if (urgencyScore >= 0.8) {
      priority = MessagePriority.critical;
    } else if (urgencyScore >= 0.6) {
      priority = MessagePriority.urgent;
    } else if (urgencyScore >= 0.4) {
      priority = MessagePriority.high;
    } else if (urgencyScore >= 0.2) {
      priority = MessagePriority.normal;
    } else {
      priority = MessagePriority.low;
    }

    // 8. Generate appropriate emojis
    suggestedEmojis = _generateEmojis(cleanContent, priority, detectedConcerns);

    return MessageAnalysis(
      priority: priority,
      urgencyScore: urgencyScore,
      suggestedEmojis: suggestedEmojis,
      detectedConcerns: detectedConcerns,
    );
  }

  static MessagePriority _getBestPriority(MessagePriority current, MessagePriority candidate) {
    return candidate.level > current.level ? candidate : current;
  }

  static List<String> _generateEmojis(String content, MessagePriority priority, List<String> concerns) {
    List<String> emojis = [];

    // Add priority emoji
    emojis.add(priority.emoji);

    // Add emotional context emojis
    if (concerns.any((c) => ['sad', 'depressed', 'hopeless'].contains(c))) {
      emojis.addAll(['😢', '💔', '🫂']);
    }
    
    if (concerns.any((c) => ['anxious', 'worried', 'scared'].contains(c))) {
      emojis.addAll(['😰', '💛', '🤗']);
    }
    
    if (concerns.any((c) => ['stressed', 'overwhelmed'].contains(c))) {
      emojis.addAll(['😤', '🌊', '🧘‍♀️']);
    }
    
    if (concerns.any((c) => ['angry', 'frustrated'].contains(c))) {
      emojis.addAll(['😡', '🔥', '🌈']);
    }

    // Supportive emojis for any mental health content
    if (priority.level >= MessagePriority.normal.level) {
      emojis.addAll(['💚', '🌟', '💪']);
    }

    // Questions get thinking emoji
    if (content.contains('?')) {
      emojis.add('🤔');
    }

    // Gratitude gets heart emojis
    if (content.toLowerCase().contains(RegExp(r'\b(thank|grateful|appreciate)\b'))) {
      emojis.addAll(['💖', '🙏']);
    }

    // Remove duplicates and limit to 5 emojis
    return emojis.toSet().take(5).toList();
  }
}

class MessageAnalysis {
  final MessagePriority priority;
  final double urgencyScore;
  final List<String> suggestedEmojis;
  final List<String> detectedConcerns;

  MessageAnalysis({
    required this.priority,
    required this.urgencyScore,
    required this.suggestedEmojis,
    required this.detectedConcerns,
  });
}