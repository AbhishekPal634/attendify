import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { student, teacher, admin }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student; // Default to student
    }
  }
}

class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Check if user has a role assigned
  Future<bool> hasRole(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists &&
          doc.data() != null &&
          (doc.data() as Map<String, dynamic>).containsKey('role');
    } catch (e) {
      print('Error checking if user has role: $e');
      return false;
    }
  }

  /// Get user role
  Future<UserRole?> getUserRole(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('role')) {
          return UserRoleExtension.fromString(data['role']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  /// Assign role to user
  Future<void> assignRole(String userId, UserRole role, {String? email}) async {
    try {
      final userData = {
        'role': role.value,
        'email': email ?? _auth.currentUser?.email,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(userId).set(userData, SetOptions(merge: true));
      print('✅ Role ${role.value} assigned to user $userId');
    } catch (e) {
      print('Error assigning role: $e');
      throw Exception('Failed to assign role: $e');
    }
  }

  /// Update user role
  Future<void> updateRole(String userId, UserRole newRole) async {
    try {
      await _usersCollection.doc(userId).update({
        'role': newRole.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Role updated to ${newRole.value} for user $userId');
    } catch (e) {
      print('Error updating role: $e');
      throw Exception('Failed to update role: $e');
    }
  }

  /// Get current user role
  Future<UserRole?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await getUserRole(user.uid);
    }
    return null;
  }

  /// Check if current user has specific role
  Future<bool> hasCurrentUserRole(UserRole role) async {
    final currentRole = await getCurrentUserRole();
    return currentRole == role;
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    return await hasCurrentUserRole(UserRole.admin);
  }

  /// Check if current user is teacher
  Future<bool> isCurrentUserTeacher() async {
    return await hasCurrentUserRole(UserRole.teacher);
  }

  /// Check if current user is student
  Future<bool> isCurrentUserStudent() async {
    return await hasCurrentUserRole(UserRole.student);
  }

  /// TEMPORARY FUNCTION - Remove this after initial setup
  /// This function assigns 'student' role to users who don't have any role
  /// ⚠️ COMMENT OUT OR REMOVE THIS FUNCTION AFTER INITIAL ROLE ASSIGNMENT ⚠️
  Future<void> assignDefaultRoleIfNeeded(String userId, {String? email}) async {
    try {
      final hasExistingRole = await hasRole(userId);

      if (!hasExistingRole) {
        print(
          '🔄 User $userId has no role assigned, setting default role: student',
        );
        await assignRole(userId, UserRole.student, email: email);
        print('✅ Default role (student) assigned to user $userId');
      } else {
        final currentRole = await getUserRole(userId);
        print('👤 User $userId already has role: ${currentRole?.value}');
      }
    } catch (e) {
      print('❌ Error in assignDefaultRoleIfNeeded: $e');
    }
  }

  /// Get all users with specific role (admin only)
  Future<List<Map<String, dynamic>>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _usersCollection
          .where('role', isEqualTo: role.value)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      throw Exception('Failed to get users by role: $e');
    }
  }

  /// Check if user can access admin features
  Future<bool> canAccessAdminFeatures() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  /// Check if user can access teacher features
  Future<bool> canAccessTeacherFeatures() async {
    final role = await getCurrentUserRole();
    return role == UserRole.teacher || role == UserRole.admin;
  }

  /// Check if user can mark attendance
  Future<bool> canMarkAttendance() async {
    return await canAccessTeacherFeatures();
  }

  /// Check if user can view all attendance records
  Future<bool> canViewAllAttendance() async {
    return await canAccessTeacherFeatures();
  }

  /// Delete user role (admin only)
  Future<void> deleteUserRole(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      print('✅ User role deleted for user $userId');
    } catch (e) {
      print('Error deleting user role: $e');
      throw Exception('Failed to delete user role: $e');
    }
  }
}
