import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/course.dart';
import '../models/lecture_session.dart';
import '../models/attendance_record.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _coursesCollection =>
      _firestore.collection('courses');
  CollectionReference get _sessionsCollection =>
      _firestore.collection('sessions');
  CollectionReference get _attendanceCollection =>
      _firestore.collection('attendance');
  CollectionReference get _usersCollection => _firestore.collection('users');

  String? get currentUserId => _auth.currentUser?.uid;

  // Course Operations
  Future<void> createCourse(Course course) async {
    try {
      await _coursesCollection.doc(course.id).set(course.toMap());
      print('✅ Course created: ${course.courseName}');
    } catch (e) {
      print('❌ Error creating course: $e');
      throw Exception('Failed to create course: $e');
    }
  }

  Future<List<Course>> getFacultyCourses(String facultyId) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('facultyId', isEqualTo: facultyId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => Course.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting faculty courses: $e');
      throw Exception('Failed to get courses: $e');
    }
  }

  Future<Course?> getCourse(String courseId) async {
    try {
      final doc = await _coursesCollection.doc(courseId).get();
      if (doc.exists) {
        return Course.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print('❌ Error getting course: $e');
      throw Exception('Failed to get course: $e');
    }
  }

  Future<void> updateCourse(Course course) async {
    try {
      await _coursesCollection
          .doc(course.id)
          .update(course.copyWith(updatedAt: DateTime.now()).toMap());
      print('✅ Course updated: ${course.courseName}');
    } catch (e) {
      print('❌ Error updating course: $e');
      throw Exception('Failed to update course: $e');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      // Delete related sessions and attendance first
      await _deleteCourseSessions(courseId);
      await _deleteCourseAttendance(courseId);

      // Delete the course
      await _coursesCollection.doc(courseId).delete();
      print('✅ Course deleted: $courseId');
    } catch (e) {
      print('❌ Error deleting course: $e');
      throw Exception('Failed to delete course: $e');
    }
  }

  // Student Enrollment Operations
  Future<bool> addStudentToCourse(String courseId, String studentEmail) async {
    try {
      // Find student by email
      final studentQuery = await _usersCollection
          .where('email', isEqualTo: studentEmail)
          .where('role', isEqualTo: 'student')
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        throw Exception('Student not found with email: $studentEmail');
      }

      final studentId = studentQuery.docs.first.id;

      // Add student to course
      await _coursesCollection.doc(courseId).update({
        'enrolledStudentIds': FieldValue.arrayUnion([studentId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Student $studentEmail added to course $courseId');
      return true;
    } catch (e) {
      print('❌ Error adding student to course: $e');
      throw Exception('Failed to add student: $e');
    }
  }

  Future<void> removeStudentFromCourse(
    String courseId,
    String studentId,
  ) async {
    try {
      await _coursesCollection.doc(courseId).update({
        'enrolledStudentIds': FieldValue.arrayRemove([studentId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Student $studentId removed from course $courseId');
    } catch (e) {
      print('❌ Error removing student from course: $e');
      throw Exception('Failed to remove student: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCourseStudents(String courseId) async {
    try {
      final course = await getCourse(courseId);
      if (course == null || course.enrolledStudentIds.isEmpty) {
        return [];
      }

      final students = <Map<String, dynamic>>[];

      // Batch get students (Firestore limit: 10 documents per batch)
      for (int i = 0; i < course.enrolledStudentIds.length; i += 10) {
        final batch = course.enrolledStudentIds.skip(i).take(10).toList();
        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentData = {
            'id': doc.id,
            'faceRegistered': data['faceRegistered'] ?? false,
            ...data,
          };

          // Only add name and email if they exist, don't insert placeholders
          if (data['name'] != null) {
            studentData['name'] = data['name'];
          }
          if (data['email'] != null) {
            studentData['email'] = data['email'];
          }

          students.add(studentData);
        }
      }

      return students;
    } catch (e) {
      print('❌ Error getting course students: $e');
      throw Exception('Failed to get course students: $e');
    }
  }

  // Session Operations
  Future<String> createSession(LectureSession session) async {
    try {
      final docRef = await _sessionsCollection.add(session.toMap());

      // Update with generated ID
      await docRef.update({'id': docRef.id});

      print('✅ Session created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating session: $e');
      throw Exception('Failed to create session: $e');
    }
  }

  Future<String> startSession(String sessionId) async {
    try {
      // Generate ephemeral session token
      final sessionToken = _generateSessionToken();

      await _sessionsCollection.doc(sessionId).update({
        'status': 'active',
        'sessionToken': sessionToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create attendance records for all enrolled students
      await _createAttendanceRecords(sessionId);

      print('✅ Session started: $sessionId with token: $sessionToken');
      return sessionToken;
    } catch (e) {
      print('❌ Error starting session: $e');
      throw Exception('Failed to start session: $e');
    }
  }

  Future<void> endSession(String sessionId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'sessionToken': null, // Remove token when session ends
      });

      print('✅ Session ended: $sessionId');
    } catch (e) {
      print('❌ Error ending session: $e');
      throw Exception('Failed to end session: $e');
    }
  }

  Future<List<LectureSession>> getCourseSessions(String courseId) async {
    try {
      final querySnapshot = await _sessionsCollection
          .where('courseId', isEqualTo: courseId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => LectureSession.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting course sessions: $e');
      throw Exception('Failed to get course sessions: $e');
    }
  }

  Future<List<LectureSession>> getFacultyActiveSessions(
    String facultyId,
  ) async {
    try {
      final querySnapshot = await _sessionsCollection
          .where('facultyId', isEqualTo: facultyId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map(
            (doc) => LectureSession.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting active sessions: $e');
      throw Exception('Failed to get active sessions: $e');
    }
  }

  // Attendance Operations
  Future<List<AttendanceRecord>> getSessionAttendance(String sessionId) async {
    try {
      final querySnapshot = await _attendanceCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => AttendanceRecord.fromMap({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('❌ Error getting session attendance: $e');
      throw Exception('Failed to get session attendance: $e');
    }
  }

  Future<void> markAttendance(
    String attendanceRecordId,
    AttendanceStatus status, {
    String? notes,
  }) async {
    try {
      await _attendanceCollection.doc(attendanceRecordId).update({
        'status': status.toString().split('.').last,
        'markedAt': FieldValue.serverTimestamp(),
        'markedBy': currentUserId,
        'notes': notes,
      });

      print('✅ Attendance marked: $attendanceRecordId as $status');
    } catch (e) {
      print('❌ Error marking attendance: $e');
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // Helper Methods
  String _generateSessionToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _createAttendanceRecords(String sessionId) async {
    try {
      final session = await _sessionsCollection.doc(sessionId).get();
      if (!session.exists) return;

      final sessionData = session.data() as Map<String, dynamic>;
      final courseId = sessionData['courseId'];

      final course = await getCourse(courseId);
      if (course == null) return;

      final batch = _firestore.batch();

      for (final studentId in course.enrolledStudentIds) {
        final attendanceRecord = AttendanceRecord(
          id: '', // Will be set by Firestore
          sessionId: sessionId,
          courseId: courseId,
          studentId: studentId,
          status: AttendanceStatus.pending,
        );

        final docRef = _attendanceCollection.doc();
        batch.set(docRef, attendanceRecord.copyWith(id: docRef.id).toMap());
      }

      await batch.commit();
      print('✅ Attendance records created for session: $sessionId');
    } catch (e) {
      print('❌ Error creating attendance records: $e');
    }
  }

  Future<void> _deleteCourseSessions(String courseId) async {
    try {
      final sessions = await getCourseSessions(courseId);
      final batch = _firestore.batch();

      for (final session in sessions) {
        batch.delete(_sessionsCollection.doc(session.id));
      }

      await batch.commit();
      print('✅ Course sessions deleted for: $courseId');
    } catch (e) {
      print('❌ Error deleting course sessions: $e');
    }
  }

  Future<void> _deleteCourseAttendance(String courseId) async {
    try {
      final querySnapshot = await _attendanceCollection
          .where('courseId', isEqualTo: courseId)
          .get();

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Course attendance deleted for: $courseId');
    } catch (e) {
      print('❌ Error deleting course attendance: $e');
    }
  }

  // Validation Methods
  Future<bool> isCourseIdUnique(String courseId, String facultyId) async {
    try {
      final querySnapshot = await _coursesCollection
          .where('courseId', isEqualTo: courseId)
          .where('facultyId', isEqualTo: facultyId)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking course ID uniqueness: $e');
      return false;
    }
  }

  Future<bool> isStudentAlreadyEnrolled(
    String courseId,
    String studentEmail,
  ) async {
    try {
      final course = await getCourse(courseId);
      if (course == null) return false;

      final studentQuery = await _usersCollection
          .where('email', isEqualTo: studentEmail)
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) return false;

      final studentId = studentQuery.docs.first.id;
      return course.enrolledStudentIds.contains(studentId);
    } catch (e) {
      print('❌ Error checking student enrollment: $e');
      return false;
    }
  }
}
