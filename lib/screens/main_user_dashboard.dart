import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../models/user.dart';
import '../tabs/home_tab.dart';
import '../tabs/messages_tab.dart';
import '../tabs/community_tab.dart';
import '../tabs/resources_tab.dart';
import '../tabs/settings_tab.dart';

class MainUserDashboard extends StatefulWidget {
  @override
  _MainUserDashboardState createState() => _MainUserDashboardState();
}

class _MainUserDashboardState extends State<MainUserDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    HomeTab(),
    MessagesTab(),
    CommunityTab(),
    ResourcesTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.currentUser == null) {
            return Center(child: Text('Please log in to access dashboard'));
          }
          return _tabs[_currentIndex];
        },
      ),
      bottomNavigationBar: Consumer<MessagingService>(
        builder: (context, messagingService, child) {
          final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
          final unreadCount = messagingService.getUnreadCount(
            currentUser?.id ?? '', 
            currentUser?.role ?? UserRole.user
          );

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.grey.shade600,
            backgroundColor: Colors.white,
            elevation: 8,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.chat),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_books),
                label: 'Resources',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}