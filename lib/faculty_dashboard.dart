import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/role_service.dart';
import 'faculty_classes_page.dart';
import 'faculty_schedule_page.dart';
import 'faculty_students_page.dart';
import 'faculty_attendance_page.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  int _selectedIndex = 0;
  final RoleService _roleService = RoleService();

  final List<FacultyPage> _pages = [
    FacultyPage(
      title: 'Classes',
      icon: Icons.class_,
      widget: const FacultyClassesPage(),
    ),
    FacultyPage(
      title: 'Schedule',
      icon: Icons.schedule,
      widget: const FacultySchedulePage(),
    ),
    FacultyPage(
      title: 'Students',
      icon: Icons.people,
      widget: const FacultyStudentsPage(),
    ),
    FacultyPage(
      title: 'Attendance',
      icon: Icons.checklist,
      widget: const FacultyAttendancePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selectedIndex].title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          FutureBuilder<String>(
            future: _getUserDisplayInfo(),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    snapshot.data ?? 'Faculty',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: MediaQuery.of(context).size.width > 800,
            backgroundColor: Theme.of(context).colorScheme.surface,
            destinations: _pages.map((page) {
              return NavigationRailDestination(
                icon: Icon(page.icon),
                selectedIcon: Icon(
                  page.icon,
                  color: Theme.of(context).primaryColor,
                ),
                label: Text(page.title),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(child: _pages[_selectedIndex].widget),
        ],
      ),
    );
  }

  Future<String> _getUserDisplayInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await _roleService.getCurrentUserRole();
      return '${user.email} (${role?.value.toUpperCase()})';
    }
    return 'Faculty';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('Dark Mode'),
              trailing: Switch(value: false, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class FacultyPage {
  final String title;
  final IconData icon;
  final Widget widget;

  FacultyPage({required this.title, required this.icon, required this.widget});
}
