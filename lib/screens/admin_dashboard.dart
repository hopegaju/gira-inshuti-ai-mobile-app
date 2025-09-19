import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showCreateCounselorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Counselor Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearControllers();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              final success = await authService.createCounselor(
                _emailController.text.trim(),
                _nameController.text.trim(),
                _passwordController.text,
              );
              
              Navigator.pop(context);
              _clearControllers();
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Counselor account created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create counselor account'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.red.shade700,
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
          final users = authService.getAllUsers();
          final userCount = users.where((u) => u.role == UserRole.user).length;
          final counselorCount = users.where((u) => u.role == UserRole.counselor).length;
          final adminCount = users.where((u) => u.role == UserRole.admin).length;

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
                      colors: [Colors.red.shade700, Colors.red.shade500],
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
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administrator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'System Management',
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
                        'Total Users',
                        userCount.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Counselors',
                        counselorCount.toString(),
                        Icons.psychology,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Admins',
                        adminCount.toString(),
                        Icons.admin_panel_settings,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateCounselorDialog,
                      icon: Icon(Icons.add),
                      label: Text('Add Counselor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                          child: Icon(
                            _getRoleIcon(user.role),
                            color: _getRoleColor(user.role),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.roleDisplayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getRoleColor(user.role),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user.isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: user.isActive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: user.role != UserRole.admin
                            ? IconButton(
                                icon: Icon(
                                  user.isActive ? Icons.block : Icons.check_circle,
                                  color: user.isActive ? Colors.red : Colors.green,
                                ),
                                onPressed: () async {
                                  final success = await authService.toggleUserStatus(user.id);
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          user.isActive
                                              ? 'User deactivated'
                                              : 'User activated',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              )
                            : null,
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.counselor:
        return Colors.green;
      case UserRole.user:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.counselor:
        return Icons.psychology;
      case UserRole.user:
        return Icons.person;
    }
  }
}