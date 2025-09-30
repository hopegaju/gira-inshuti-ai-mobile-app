// tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../models/user.dart';

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Welcome'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authService.currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    value: 'logout',
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    authService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthService, MessagingService>(
        builder: (context, authService, messagingService, child) {
          final user = authService.currentUser;
          final unreadCount = messagingService.getUnreadCount(
            user?.id ?? '',
            user?.role ?? UserRole.user,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header with mood check
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        user?.name ?? 'User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMoodButton('😊', 'Great'),
                          _buildMoodButton('😌', 'Good'),
                          _buildMoodButton('😐', 'Okay'),
                          _buildMoodButton('😔', 'Not Good'),
                          _buildMoodButton('😢', 'Bad'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread messages alert
                if (unreadCount > 0) ...[
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // Navigate to messages tab
                      DefaultTabController.of(context)?.animateTo(1);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.message,
                            color: Colors.orange.shade700,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You have $unreadCount unread message${unreadCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                Text(
                                  'Tap to view your conversations',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.orange.shade600,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 30),

                // Daily tip
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.green.shade700,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Daily Wellness Tip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        _getDailyTip(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildQuickActionCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Talk to Counselor',
                      color: Colors.blue,
                      onTap: () {
                        DefaultTabController.of(context)?.animateTo(1);
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.group_outlined,
                      title: 'Community',
                      color: Colors.purple,
                      onTap: () {
                        DefaultTabController.of(context)?.animateTo(2);
                      },
                    ),
                    _buildQuickActionCard(
                      icon: Icons.self_improvement,
                      title: 'Breathing Exercise',
                      color: Colors.teal,
                      onTap: () => _showBreathingExercise(context),
                    ),
                    _buildQuickActionCard(
                      icon: Icons.emergency,
                      title: 'Crisis Helpline',
                      color: Colors.red,
                      onTap: () => _showCrisisHelp(context),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Your Journey Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Journey',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildInfoRow('Member Since', 
                        user?.createdAt.toString().split(' ')[0] ?? ''),
                      _buildInfoRow('Total Days', 
                        _getDaysSinceJoined(user?.createdAt).toString()),
                      _buildInfoRow('Check-ins This Week', '3'),
                      _buildInfoRow('Community Support Given', '12'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodButton(String emoji, String label) {
    return GestureDetector(
      onTap: () {
        // Log mood tracking
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  String _getDailyTip() {
    final tips = [
      'Take a few minutes today to practice deep breathing. Inhale for 4 counts, hold for 4, and exhale for 6. This simple technique can help reduce stress and anxiety.',
      'Remember to stay hydrated! Drinking enough water can improve your mood, energy levels, and overall mental clarity.',
      'Try to get outside for at least 15 minutes today. Natural light and fresh air can boost your mood and vitamin D levels.',
      'Practice gratitude by writing down three things you\'re thankful for. This simple habit can significantly improve your mental wellbeing.',
      'Connect with someone you care about today. A simple message or call can strengthen your support network and lift your spirits.',
      'Take regular breaks from screens. The 20-20-20 rule: Every 20 minutes, look at something 20 feet away for 20 seconds.',
      'Move your body for at least 30 minutes today. Exercise releases endorphins that naturally improve your mood.',
    ];
    
    // Use day of week to select tip (so it changes daily but is consistent for the day)
    final dayOfWeek = DateTime.now().weekday;
    return tips[dayOfWeek % tips.length];
  }

  int _getDaysSinceJoined(DateTime? joinDate) {
    if (joinDate == null) return 0;
    return DateTime.now().difference(joinDate).inDays;
  }

  void _showBreathingExercise(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Breathing Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.self_improvement,
              size: 48,
              color: Colors.teal,
            ),
            SizedBox(height: 16),
            Text(
              '4-7-8 Breathing Technique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '1. Breathe in through your nose for 4 counts\n'
              '2. Hold your breath for 7 counts\n'
              '3. Exhale through your mouth for 8 counts\n'
              '4. Repeat 3-4 times',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Could navigate to a full breathing exercise screen
            },
            child: Text('Start Exercise'),
          ),
        ],
      ),
    );
  }

  void _showCrisisHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Crisis Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you\'re in immediate danger, please contact:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildCrisisContact('Emergency', '911'),
            _buildCrisisContact('Suicide Hotline', '988'),
            _buildCrisisContact('Crisis Text Line', 'Text HOME to 741741'),
            SizedBox(height: 16),
            Text(
              'You are not alone. Help is available.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisContact(String label, String number) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.phone, size: 16, color: Colors.red),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Text(number, style: TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}