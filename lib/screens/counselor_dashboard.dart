import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class CounselorDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Counselor Dashboard'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'C',
                    style: TextStyle(
                      color: Colors.green.shade700,
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
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          final allUsers = authService.getAllUsers();
          final regularUsers = allUsers.where((u) => u.role == UserRole.user).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Counselor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Professional Counselor',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active Clients',
                        regularUsers.where((u) => u.isActive).length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Sessions',
                        '24', // Mock data
                        Icons.event,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'This Week',
                        '6', // Mock data
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
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
                  children: [
                    _buildActionCard(
                      icon: Icons.schedule,
                      title: 'Schedule Session',
                      subtitle: 'Book new appointments',
                      color: Colors.blue,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Scheduling feature coming soon!')),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.chat,
                      title: 'Messages',
                      subtitle: 'Client communications',
                      color: Colors.green,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Messaging feature coming soon!')),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.assessment,
                      title: 'Reports',
                      subtitle: 'Session summaries',
                      color: Colors.orange,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reports feature coming soon!')),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.library_books,
                      title: 'Resources',
                      subtitle: 'Therapeutic materials',
                      color: Colors.purple,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Resources feature coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  'Recent Clients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                Container(
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
                  child: regularUsers.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No clients yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Clients will appear here once they register',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: regularUsers.length,
                          separatorBuilder: (context, index) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final client = regularUsers[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: Text(
                                  client.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                client.name,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(client.email),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: client.isActive
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      client.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: client.isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.message, color: Colors.green.shade600),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Messaging ${client.name}...'),
                                    ),
                                  );
                                },
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}