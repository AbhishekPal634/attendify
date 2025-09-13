import 'package:flutter/material.dart';
import 'role_service.dart';

class RoleBasedNavigationHelper {
  static final RoleService _roleService = RoleService();

  /// Get the appropriate dashboard route based on user role
  static Future<String> getDashboardRoute() async {
    final role = await _roleService.getCurrentUserRole();

    switch (role) {
      case UserRole.admin:
        return '/admin-dashboard';
      case UserRole.teacher:
        return '/teacher-dashboard';
      case UserRole.student:
      default:
        return '/student-dashboard';
    }
  }

  /// Navigate to appropriate dashboard based on user role
  static Future<void> navigateToDashboard(BuildContext context) async {
    final route = await getDashboardRoute();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  /// Check if user can access a specific route
  static Future<bool> canAccessRoute(String route) async {
    final role = await _roleService.getCurrentUserRole();

    // Define route permissions
    final routePermissions = {
      '/admin-dashboard': [UserRole.admin],
      '/teacher-dashboard': [UserRole.teacher, UserRole.admin],
      '/student-dashboard': [
        UserRole.student,
        UserRole.teacher,
        UserRole.admin,
      ],
      '/mark-attendance': [UserRole.teacher, UserRole.admin],
      '/view-all-attendance': [UserRole.teacher, UserRole.admin],
      '/manage-users': [UserRole.admin],
      '/profile': [UserRole.student, UserRole.teacher, UserRole.admin],
    };

    if (role == null) return false;

    final allowedRoles = routePermissions[route];
    return allowedRoles?.contains(role) ?? false;
  }

  /// Get user role display name
  static Future<String> getUserRoleDisplayName() async {
    final role = await _roleService.getCurrentUserRole();

    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      default:
        return 'Unknown';
    }
  }

  /// Get available menu items based on user role
  static Future<List<NavigationItem>> getNavigationItems() async {
    final role = await _roleService.getCurrentUserRole();

    List<NavigationItem> items = [
      NavigationItem(
        title: 'Profile',
        icon: Icons.person,
        route: '/profile',
        roles: [UserRole.student, UserRole.teacher, UserRole.admin],
      ),
    ];

    // Add role-specific items
    switch (role) {
      case UserRole.admin:
        items.addAll([
          NavigationItem(
            title: 'Admin Dashboard',
            icon: Icons.admin_panel_settings,
            route: '/admin-dashboard',
            roles: [UserRole.admin],
          ),
          NavigationItem(
            title: 'Manage Users',
            icon: Icons.people,
            route: '/manage-users',
            roles: [UserRole.admin],
          ),
          NavigationItem(
            title: 'View All Attendance',
            icon: Icons.analytics,
            route: '/view-all-attendance',
            roles: [UserRole.admin],
          ),
        ]);
        break;
      case UserRole.teacher:
        items.addAll([
          NavigationItem(
            title: 'Teacher Dashboard',
            icon: Icons.school,
            route: '/teacher-dashboard',
            roles: [UserRole.teacher, UserRole.admin],
          ),
          NavigationItem(
            title: 'Mark Attendance',
            icon: Icons.checklist,
            route: '/mark-attendance',
            roles: [UserRole.teacher, UserRole.admin],
          ),
          NavigationItem(
            title: 'View Attendance',
            icon: Icons.visibility,
            route: '/view-all-attendance',
            roles: [UserRole.teacher, UserRole.admin],
          ),
        ]);
        break;
      case UserRole.student:
      default:
        items.add(
          NavigationItem(
            title: 'Student Dashboard',
            icon: Icons.dashboard,
            route: '/student-dashboard',
            roles: [UserRole.student, UserRole.teacher, UserRole.admin],
          ),
        );
        break;
    }

    // Filter items based on current role
    return items.where((item) => item.roles.contains(role)).toList();
  }

  /// Widget builder for role-based content
  static Widget buildRoleBasedWidget({
    required Widget Function() studentWidget,
    required Widget Function() teacherWidget,
    required Widget Function() adminWidget,
    Widget Function()? loadingWidget,
  }) {
    return FutureBuilder<UserRole?>(
      future: _roleService.getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget?.call() ??
              const Center(child: CircularProgressIndicator());
        }

        final role = snapshot.data;
        switch (role) {
          case UserRole.admin:
            return adminWidget();
          case UserRole.teacher:
            return teacherWidget();
          case UserRole.student:
          default:
            return studentWidget();
        }
      },
    );
  }

  /// Show role-based action button
  static Widget? buildRoleBasedActionButton({
    Widget? studentButton,
    Widget? teacherButton,
    Widget? adminButton,
  }) {
    return FutureBuilder<UserRole?>(
      future: _roleService.getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final role = snapshot.data;
        switch (role) {
          case UserRole.admin:
            return adminButton ?? const SizedBox.shrink();
          case UserRole.teacher:
            return teacherButton ?? const SizedBox.shrink();
          case UserRole.student:
            return studentButton ?? const SizedBox.shrink();
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  /// Route guard for protecting routes
  static Future<bool> routeGuard(String route) async {
    return await canAccessRoute(route);
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final List<UserRole> roles;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.roles,
  });
}
