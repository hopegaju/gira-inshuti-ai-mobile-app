class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final MoodService _moodService = MoodService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F2F1),
      appBar: AppBar(
        title: Text('Gira Inshuti'),
        backgroundColor: Color(0xFF00695C),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Daily Check-in',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('How are you feeling today?'),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _moodButton('😊', 'Great'),
                        _moodButton('🙂', 'Good'),
                        _moodButton('😐', 'Okay'),
                        _moodButton('😔', 'Low'),
                        _moodButton('😢', 'Sad'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: _postService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading posts'));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Be the first to share your thoughts!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return PostCard(post: snapshot.data![index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodButton(String emoji, String label) {
    return GestureDetector(
      onTap: () async {
        await _moodService.logMood(label);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mood logged: $label')),
        );
      },
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Firebase Configuration
class FirebaseConfig {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-api-key',
    appId: 'your-app-id',
    messagingSenderId: 'your-messaging-sender-id',
    projectId: 'gira-inshuti-app',
    storageBucket: 'gira-inshuti-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'your-ios-api-key',
    appId: 'your-ios-app-id',
    messagingSenderId: 'your-messaging-sender-id',
    projectId: 'gira-inshuti-app',
    storageBucket: 'gira-inshuti-app.appspot.com',
    iosClientId: 'your-ios-client-id',
    iosBundleId: 'com.example.girainshuti',
  );
}

// Data Models
class Post {
  final String id;
  final String anonymousName;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final String category;
  final String userId;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.anonymousName,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.category,
    required this.userId,
    required this.likedBy,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      anonymousName: data['anonymousName'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      category: data['category'] ?? 'General',
      userId: data['userId'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'anonymousName': anonymousName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
      'category': category,
      'userId': userId,
      'likedBy': likedBy,
    };
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? id;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.id,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class Comment {
  final String id;
  final String postId;
  final String anonymousName;
  final String content;
  final DateTime timestamp;
  final String userId;

  Comment({
    required this.id,
    required this.postId,
    required this.anonymousName,
    required this.content,
    required this.timestamp,
    required this.userId,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      anonymousName: data['anonymousName'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'anonymousName': anonymousName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
    };
  }
}

// Services
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      await _createAnonymousUserProfile(result.user!);
      return result;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> _createAnonymousUserProfile(User user) async {
    final anonymousName = _generateAnonymousName();
    await _firestore.collection('users').doc(user.uid).set({
      'anonymousName': anonymousName,
      'createdAt': Timestamp.now(),
      'isAnonymous': true,
      'moodHistory': [],
      'lastActive': Timestamp.now(),
    });
  }

  String _generateAnonymousName() {
    final random = Random();
    return 'User${random.nextInt(9999).toString().padLeft(4, '0')}';
  }

  Future<String> getAnonymousName() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?['anonymousName'] ?? '';
      }
    }
    return '';
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  Future<void> createPost(String content, String category) async {
    final user = _authService.currentUser;
    if (user != null) {
      final anonymousName = await _authService.getAnonymousName();
      await _firestore.collection('posts').add({
        'content': content,
        'category': category,
        'anonymousName': anonymousName,
        'userId': user.uid,
        'timestamp': Timestamp.now(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      });
    }
  }

  Future<void> likePost(String postId, bool isLiked) async {
    final user = _authService.currentUser;
    if (user != null) {
      final postRef = _firestore.collection('posts').doc(postId);
      
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([user.uid]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([user.uid]),
        });
      }
    }
  }

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
  }

  Future<void> addComment(String postId, String content) async {
    final user = _authService.currentUser;
    if (user != null) {
      final anonymousName = await _authService.getAnonymousName();
      
      // Add comment
      await _firestore.collection('comments').add({
        'postId': postId,
        'content': content,
        'anonymousName': anonymousName,
        'userId': user.uid,
        'timestamp': Timestamp.now(),
      });

      // Increment comment count
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
    }
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Stream<List<ChatMessage>> getChatMessages() {
    final user = _authService.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .orderBy('timestamp')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
    }
    return Stream.value([]);
  }

  Future<void> sendMessage(String text, bool isUser) async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .add({
        'text': text,
        'isUser': isUser,
        'timestamp': Timestamp.now(),
      });
    }
  }

  Future<String> generateAIResponse(String userMessage) async {
    // Simple keyword-based response system
    // In production, integrate with actual AI service like OpenAI or custom model
    Map<String, List<String>> responses = {
      'anxiety': [
        "I understand you're feeling anxious. Anxiety is a common experience, and there are ways to manage it.",
        "When anxiety strikes, try the 4-7-8 breathing technique: breathe in for 4, hold for 7, exhale for 8.",
        "Anxiety can feel overwhelming, but remember that these feelings will pass. You're stronger than you know.",
      ],
      'depression': [
        "Thank you for sharing your feelings with me. Depression can make everything feel heavy, but you're not alone.",
        "Small steps can make a big difference. Have you been able to do one small thing for yourself today?",
        "Depression affects many people. It's important to be gentle with yourself during difficult times.",
      ],
      'stress': [
        "Stress can be overwhelming. What's been the biggest source of stress for you lately?",
        "Managing stress is important for your wellbeing. Have you tried any relaxation techniques?",
        "It sounds like you're dealing with a lot. Remember that it's okay to ask for help when you need it.",
      ],
      'sleep': [
        "Sleep problems can really affect how we feel. Have you noticed any patterns in your sleep difficulties?",
        "Good sleep hygiene can help: try keeping a consistent bedtime and avoiding screens before bed.",
        "Sleep is crucial for mental health. Consider speaking with a healthcare provider if problems persist.",
      ],
      'default': [
        "I hear you, and I want you to know that your feelings are valid.",
        "Thank you for sharing that with me. It takes courage to open up.",
        "I'm here to support you. Would you like to talk more about what's on your mind?",
        "Your mental health matters. How can I best support you right now?",
        "It sounds like you're going through something difficult. You don't have to face this alone.",
      ]
    };

    String category = 'default';
    String lowerMessage = userMessage.toLowerCase();
    
    for (String key in responses.keys) {
      if (key != 'default' && lowerMessage.contains(key)) {
        category = key;
        break;
      }
    }

    List<String> categoryResponses = responses[category]!;
    return categoryResponses[Random().nextInt(categoryResponses.length)];
  }
}

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<void> logMood(String mood) async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moodEntries')
          .add({
        'mood': mood,
        'timestamp': Timestamp.now(),
      });

      // Update user's mood history
      await _firestore.collection('users').doc(user.uid).update({
        'lastMood': mood,
        'lastMoodTimestamp': Timestamp.now(),
        'lastActive': Timestamp.now(),
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getMoodHistory() {
    final user = _authService.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moodEntries')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList());
    }
    return Stream.value([]);
  }
}

// Push Notifications Service
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission();
    
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.title}');
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Background message: ${message.notification?.title}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseConfig.android, // Use appropriate config for platform
  );
  
  // Initialize notifications
  await NotificationService().initialize();
  
  runApp(GiraInshutiApp());
}

class GiraInshutiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gira Inshuti',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColor: Color(0xFF00695C),
        accentColor: Color(0xFF4DB6AC),
        backgroundColor: Color(0xFFE0F2F1),
        fontFamily: 'Roboto',
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        } else if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00695C),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Gira Inshuti',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your Mental Health Companion',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 60),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: Color(0xFF00695C),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Anonymous & Safe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00695C),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your identity is completely protected. Share your thoughts and get support without revealing who you are.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInAnonymously,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00695C),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Enter Anonymously',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? result = await _authService.signInAnonymously();
      if (result != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } else {
        _showErrorDialog('Failed to sign in. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please check your connection and try again.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00695C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Gira Inshuti',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your Mental Health Companion',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> onboardingData = [
    OnboardingData(
      icon: Icons.security,
      title: 'Safe & Anonymous',
      description: 'Share your thoughts and feelings in a secure, semi-anonymous environment.',
    ),
    OnboardingData(
      icon: Icons.psychology,
      title: 'AI Support',
      description: 'Get instant support from our AI companion trained in mental health assistance.',
    ),
    OnboardingData(
      icon: Icons.people,
      title: 'Community Support',
      description: 'Connect with others who understand your journey and offer mutual support.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F2F1),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                return OnboardingPage(data: onboardingData[index]);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                  child: Text('Skip'),
                ),
                Row(
                  children: List.generate(
                    onboardingData.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Color(0xFF00695C)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    }
                  },
                  child: Text(_currentPage == onboardingData.length - 1 ? 'Start' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  OnboardingData({required this.icon, required this.title, required this.description});
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data.icon,
            size: 100,
            color: Color(0xFF00695C),
          ),
          SizedBox(height: 40),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00695C),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            data.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  String anonymousId = '';

  @override
  void initState() {
    super.initState();
    _loadAnonymousId();
  }

  Future<void> _loadAnonymousId() async {
    String id = await _authService.getAnonymousName();
    setState(() {
      anonymousId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          FeedScreen(),
          ChatScreen(),
          ShareScreen(),
          ResourcesScreen(),
          ProfileScreen(anonymousId: anonymousId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Color(0xFF00695C),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Share',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> posts = [
    Post(
      id: '1',
      anonymousName: 'User0234',
      content: 'Been struggling with anxiety lately. The constant worry is exhausting. Anyone else feeling this way?',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      likes: 12,
      comments: 5,
      category: 'Anxiety',
    ),
    Post(
      id: '2',
      anonymousName: 'User0891',
      content: 'Taking small steps towards healing. Today I managed to go for a walk outside. Small victories matter.',
      timestamp: DateTime.now().subtract(Duration(hours: 4)),
      likes: 28,
      comments: 8,
      category: 'Recovery',
    ),
    Post(
      id: '3',
      anonymousName: 'User0567',
      content: 'Does anyone have tips for dealing with sleep issues? I\'ve been having trouble falling asleep for weeks now.',
      timestamp: DateTime.now().subtract(Duration(hours: 6)),
      likes: 15,
      comments: 12,
      category: 'Sleep',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F2F1),
      appBar: AppBar(
        title: Text('Gira Inshuti'),
        backgroundColor: Color(0xFF00695C),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Daily Check-in',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('How are you feeling today?'),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _moodButton('😊', 'Great'),
                        _moodButton('🙂', 'Good'),
                        _moodButton('😐', 'Okay'),
                        _moodButton('😔', 'Low'),
                        _moodButton('😢', 'Sad'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: posts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodButton(String emoji, String label) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mood logged: $label')),
        );
      },
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post.likes;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF00695C),
                  child: Text(
                    widget.post.anonymousName[0],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.anonymousName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatTimestamp(widget.post.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    widget.post.category,
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Color(0xFF4DB6AC).withOpacity(0.2),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              widget.post.content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLiked = !isLiked;
                      likeCount += isLiked ? 1 : -1;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text('$likeCount'),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(post: widget.post),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.comment, color: Colors.grey, size: 20),
                      SizedBox(width: 4),
                      Text('${widget.post.comments}'),
                    ],
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.share, size: 20),
                  onPressed: () {
                    // Handle share
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> messages = [];
  TextEditingController _messageController = TextEditingController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    messages.add(
      ChatMessage(
        text: "Hello! I'm your AI companion. I'm here to listen and support you. How are you feeling today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Companion'),
        backgroundColor: Color(0xFF00695C),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isTyping) {
                  return TypingIndicator();
                }
                return ChatBubble(message: messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Color(0xFF00695C),
                  mini: true,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add(
        ChatMessage(
          text: _messageController.text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      isTyping = true;
    });

    String userMessage = _messageController.text;
    _messageController.clear();

    // Simulate AI response
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isTyping = false;
        messages.add(
          ChatMessage(
            text: _generateAIResponse(userMessage),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
  }

  String _generateAIResponse(String userMessage) {
    List<String> responses = [
      "I hear you, and I want you to know that your feelings are valid. It's okay to feel this way.",
      "Thank you for sharing that with me. It takes courage to open up about your feelings.",
      "I'm here to support you. Would you like to talk more about what's troubling you?",
      "It sounds like you're going through a difficult time. Remember that you're not alone in this.",
      "Your mental health matters. Have you considered talking to a professional counselor about this?",
      "That must be really challenging for you. What usually helps you feel a bit better?",
      "I appreciate you trusting me with your thoughts. How long have you been feeling this way?",
    ];
    
    return responses[Random().nextInt(responses.length)];
  }
}

class ShareScreen extends StatefulWidget {
  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  TextEditingController _contentController = TextEditingController();
  String selectedCategory = 'General';
  List<String> categories = [
    'General',
    'Anxiety',
    'Depression',
    'Stress',
    'Recovery',
    'Sleep',
    'Relationships',
    'Work/Study',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Your Thoughts'),
        backgroundColor: Color(0xFF00695C),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Color(0xFF00695C)),
                        SizedBox(width: 8),
                        Text(
                          'Anonymous Sharing',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your identity is protected. Share freely and safely.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            Text(
              'What\'s on your mind?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts, feelings, or ask for support...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_contentController.text.trim().isNotEmpty) {
                    _sharePost();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00695C),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Share Anonymously',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Post Shared'),
          content: Text('Your thoughts have been shared anonymously with the community.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _contentController.clear();
                setState(() {
                  selectedCategory = 'General';
                });
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class ResourcesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mental Health Resources'),
        backgroundColor: Color(0xFF00695C),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _resourceCard(
            'Crisis Support',
            'Immediate help for mental health emergencies',
            Icons.emergency,
            Colors.red,
            () => _showCrisisSupport(context),
          ),
          _resourceCard(
            'Breathing Exercises',
            'Guided breathing techniques for anxiety and stress',
            Icons.air,
            Colors.blue,
            () => _showBreathingExercise(context),
          ),
          _resourceCard(
            'Meditation Guide',
            'Mindfulness and meditation practices',
            Icons.self_improvement,
            Colors.purple,
            () => _showMeditationGuide(context),
          ),
          _resourceCard(
            'Sleep Tips',
            'Improve your sleep hygiene and quality',
            Icons.bedtime,
            Colors.indigo,
            () => _showSleepTips(context),
          ),
          _resourceCard(
            'Professional Help',
            'Find mental health professionals in Rwanda',
            Icons.local_hospital,
            Colors.green,
            () => _showProfessionalHelp(context),
          ),
          _resourceCard(
            'Educational Articles',
            'Learn about mental health conditions and treatments',
            Icons.school,
            Colors.orange,
            () => _showEducationalContent(context),
          ),
        ],
      ),
    );
  }

  Widget _resourceCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        onTap: onTap,
        trailing: Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  void _showCrisisSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crisis Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('If you\'re having thoughts of self-harm or suicide, please reach out immediately:'),
              SizedBox(height: 16),
              Text('• Emergency: 112'),
              Text('• Mental Health Hotline: +250 788 123 456'),
              Text('• Rwanda Biomedical Center: +250 788 789 123'),
              SizedBox(height: 16),
              Text('You are not alone. Help is available 24/7.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showBreathingExercise(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => BreathingExerciseScreen()),
    );
  }

  void _showMeditationGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Meditation Guide'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Simple 5-minute meditation:'),
                SizedBox(height: 12),
                Text('1. Find a comfortable position'),
                Text('2. Close your eyes or soften your gaze'),
                Text('3. Focus on your breath'),
                Text('4. When your mind wanders, gently return to your breath'),
                Text('5. Continue for 5 minutes'),
                SizedBox(height: 16),
                Text('Practice daily for best results.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSleepTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sleep Tips'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Improve your sleep with these tips:'),
                SizedBox(height: 12),
                Text('• Keep a consistent sleep schedule'),
                Text('• Create a relaxing bedtime routine'),
                Text('• Avoid screens 1 hour before bed'),
                Text('• Keep your bedroom cool and dark'),
                Text('• Limit caffeine after 2 PM'),
                Text('• Exercise regularly, but not before bed'),
                Text('• If you can\'t sleep, get up and do a quiet activity'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showProfessionalHelp(BuildContext context) {
    showDialog(