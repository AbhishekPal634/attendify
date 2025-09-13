import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/session.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _studentsCollection =>
      _firestore.collection('students');
  CollectionReference get _subjectsCollection =>
      _firestore.collection('subjects');
  CollectionReference get _sessionsCollection =>
      _firestore.collection('sessions');

  // Student Operations
  Future<void> createStudent(Student student) async {
    try {
      await _studentsCollection.doc(student.id).set(student.toMap());
    } catch (e) {
      throw Exception('Failed to create student: $e');
    }
  }

  Future<Student?> getStudent(String studentId) async {
    try {
      final doc = await _studentsCollection.doc(studentId).get();
      if (doc.exists) {
        return Student.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get student: $e');
    }
  }

  Future<Student?> getStudentByEmail(String email) async {
    try {
      print('🔍 Searching for student with email: $email');
      final querySnapshot = await _studentsCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      print('📊 Query result: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isNotEmpty) {
        final studentData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;
        print(
          '✅ Found student data: ${studentData['name']} (${studentData['email']})',
        );
        return Student.fromMap(studentData);
      }

      print('❌ No student found with email: $email');
      return null;
    } catch (e) {
      print('🚨 Error getting student by email: $e');
      throw Exception('Failed to get student by email: $e');
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      await _studentsCollection.doc(student.id).update(student.toMap());
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  // Subject Operations
  Future<List<Subject>> getStudentSubjects(String studentId) async {
    try {
      final querySnapshot = await _subjectsCollection
          .where('enrolledStudents', arrayContains: studentId)
          .get();

      return querySnapshot.docs
          .map((doc) => Subject.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student subjects: $e');
    }
  }

  Future<Subject?> getSubject(String subjectId) async {
    try {
      final doc = await _subjectsCollection.doc(subjectId).get();
      if (doc.exists) {
        return Subject.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get subject: $e');
    }
  }

  // Session Operations
  Future<List<Session>> getStudentSessions(String studentId) async {
    print('[DEBUG] Getting sessions for student: $studentId');

    try {
      final studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();
      if (!studentDoc.exists) {
        print('[DEBUG] Student not found: $studentId');
        return [];
      }

      final subjectIds = List<String>.from(
        studentDoc.data()!['subjectIds'] ?? [],
      );
      print('[DEBUG] Student subject IDs: $subjectIds');

      if (subjectIds.isEmpty) {
        print('[DEBUG] No subjects for student');
        return [];
      }

      // Get all sessions without any filters to avoid index requirements
      print('[DEBUG] Fetching all sessions from Firestore...');
      final sessionsSnapshot = await _firestore.collection('sessions').get();
      print('[DEBUG] Fetched ${sessionsSnapshot.docs.length} total sessions');

      final sessions = <Session>[];
      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        final sessionSubjectId = data['subjectId'];
        print(
          '[DEBUG] Checking session ${doc.id} with subjectId: $sessionSubjectId',
        );

        if (subjectIds.contains(sessionSubjectId)) {
          print('[DEBUG] Session ${doc.id} matches student subjects');
          // Add the document ID to the data before creating the Session object
          data['id'] = doc.id;
          sessions.add(Session.fromMap(data));
        }
      }

      // Sort by startTime descending (client-side)
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      print(
        '[DEBUG] Found ${sessions.length} sessions for student after filtering',
      );
      return sessions;
    } catch (e) {
      print('[DEBUG] Error getting student sessions: $e');
      throw Exception('Failed to get student sessions: $e');
    }
  }

  Future<List<Session>> getActiveSessions(String studentId) async {
    try {
      final subjects = await getStudentSubjects(studentId);

      if (subjects.isEmpty) return [];

      final now = DateTime.now();

      // Get all sessions and filter locally
      final querySnapshot = await _sessionsCollection.get();

      final subjectIds = subjects.map((s) => s.id).toSet();

      final activeSessions = <Session>[];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        final session = Session.fromMap(data);

        if (subjectIds.contains(session.subjectId) &&
            session.status == 'active' &&
            session.startTime.isBefore(now) &&
            session.endTime.isAfter(now)) {
          activeSessions.add(session);
        }
      }

      return activeSessions;
    } catch (e) {
      throw Exception('Failed to get active sessions: $e');
    }
  }

  Future<void> markAttendance(String sessionId, String studentId) async {
    try {
      await _sessionsCollection.doc(sessionId).update({
        'attendedStudents': FieldValue.arrayUnion([studentId]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // Attendance Analytics
  Future<Map<String, double>> getAttendancePercentage(String studentId) async {
    try {
      final subjects = await getStudentSubjects(studentId);
      final Map<String, double> attendanceMap = {};

      for (final subject in subjects) {
        final sessionsSnapshot = await _sessionsCollection
            .where('subjectId', isEqualTo: subject.id)
            .where('status', isEqualTo: 'completed')
            .get();

        final totalSessions = sessionsSnapshot.docs.length;

        if (totalSessions == 0) {
          attendanceMap[subject.name] = 0.0;
          continue;
        }

        final attendedSessions = sessionsSnapshot.docs.where((doc) {
          final session = Session.fromMap(doc.data() as Map<String, dynamic>);
          return session.attendedStudents.contains(studentId);
        }).length;

        attendanceMap[subject.name] = (attendedSessions / totalSessions) * 100;
      }

      return attendanceMap;
    } catch (e) {
      throw Exception('Failed to calculate attendance percentage: $e');
    }
  }

  Future<double> getOverallAttendancePercentage(String studentId) async {
    try {
      final attendanceMap = await getAttendancePercentage(studentId);

      if (attendanceMap.isEmpty) return 0.0;

      final totalPercentage = attendanceMap.values.reduce((a, b) => a + b);
      return totalPercentage / attendanceMap.length;
    } catch (e) {
      throw Exception('Failed to calculate overall attendance: $e');
    }
  }

  // Real-time streams
  Stream<List<Session>> getActiveSessionsStream(String studentId) {
    return _studentsCollection.doc(studentId).snapshots().asyncMap((
      studentDoc,
    ) async {
      if (!studentDoc.exists) return <Session>[];

      return await getActiveSessions(studentId);
    });
  }

  Stream<Student?> getStudentStream(String studentId) {
    return _studentsCollection.doc(studentId).snapshots().map((doc) {
      if (doc.exists) {
        return Student.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Create dummy data for new users
  Future<void> createDummyDataForUser(String email, String displayName) async {
    try {
      print('🏗️ Creating dummy data for: $email (Display: $displayName)');

      // Generate unique IDs
      final studentId = 'student_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      print('📝 Generated student ID: $studentId');

      // Create student
      final student = Student(
        id: studentId,
        name: displayName.isNotEmpty ? displayName : 'Student Name',
        email: email,
        studentId:
            'ST${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
        phone: '+1 (555) 123-4567',
        dateOfBirth: 'March 15, 2002',
        gender: 'Male',
        address: '123 Student Housing, University Ave',
        program: 'Bachelor of Computer Science',
        year: '3rd Year',
        semester: 'Fall 2024',
        cgpa: 3.85,
        creditsCompleted: 90,
        totalCredits: 120,
        expectedGraduation: 'Spring 2026',
        createdAt: now,
        updatedAt: now,
      );

      print('💾 Creating student document...');
      await createStudent(student);

      // Create subjects
      final subjects = [
        Subject(
          id: 'sub_cs101_$studentId',
          name: 'Data Structures',
          code: 'CS101',
          facultyName: 'Dr. Sarah Johnson',
          facultyEmail: 'sarah.johnson@university.edu',
          credits: 3,
          semester: 'Fall 2024',
          year: '2024',
          enrolledStudents: [studentId],
          createdAt: now,
          updatedAt: now,
        ),
        Subject(
          id: 'sub_cs201_$studentId',
          name: 'Database Systems',
          code: 'CS201',
          facultyName: 'Prof. Michael Chen',
          facultyEmail: 'michael.chen@university.edu',
          credits: 4,
          semester: 'Fall 2024',
          year: '2024',
          enrolledStudents: [studentId],
          createdAt: now,
          updatedAt: now,
        ),
        Subject(
          id: 'sub_cs301_$studentId',
          name: 'Software Engineering',
          code: 'CS301',
          facultyName: 'Dr. Emily Rodriguez',
          facultyEmail: 'emily.rodriguez@university.edu',
          credits: 3,
          semester: 'Fall 2024',
          year: '2024',
          enrolledStudents: [studentId],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final subject in subjects) {
        await _subjectsCollection.doc(subject.id).set(subject.toMap());
      }

      // Create sessions
      final sessions = [
        // Active session (happening now)
        Session(
          id: 'session_active_$studentId',
          subjectId: subjects[0].id,
          subjectName: subjects[0].name,
          facultyName: subjects[0].facultyName,
          startTime: now.subtract(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 60)),
          status: 'active',
          location: 'Room 101, CS Building',
          attendedStudents: [],
          createdAt: now,
          updatedAt: now,
        ),
        // Upcoming session
        Session(
          id: 'session_upcoming_$studentId',
          subjectId: subjects[1].id,
          subjectName: subjects[1].name,
          facultyName: subjects[1].facultyName,
          startTime: now.add(const Duration(hours: 2)),
          endTime: now.add(const Duration(hours: 3, minutes: 30)),
          status: 'scheduled',
          location: 'Room 205, CS Building',
          attendedStudents: [],
          createdAt: now,
          updatedAt: now,
        ),
        // Completed session (for attendance calculation)
        Session(
          id: 'session_completed_1_$studentId',
          subjectId: subjects[0].id,
          subjectName: subjects[0].name,
          facultyName: subjects[0].facultyName,
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now
              .subtract(const Duration(days: 1))
              .add(const Duration(hours: 1, minutes: 30)),
          status: 'completed',
          location: 'Room 101, CS Building',
          attendedStudents: [studentId], // Student attended
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(days: 1)),
        ),
        // Another completed session (missed)
        Session(
          id: 'session_completed_2_$studentId',
          subjectId: subjects[1].id,
          subjectName: subjects[1].name,
          facultyName: subjects[1].facultyName,
          startTime: now.subtract(const Duration(days: 2)),
          endTime: now
              .subtract(const Duration(days: 2))
              .add(const Duration(hours: 1, minutes: 30)),
          status: 'completed',
          location: 'Room 205, CS Building',
          attendedStudents: [], // Student missed this one
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        // Today's completed session
        Session(
          id: 'session_today_$studentId',
          subjectId: subjects[2].id,
          subjectName: subjects[2].name,
          facultyName: subjects[2].facultyName,
          startTime: DateTime(now.year, now.month, now.day, 9, 0),
          endTime: DateTime(now.year, now.month, now.day, 10, 30),
          status: 'completed',
          location: 'Room 301, CS Building',
          attendedStudents: [studentId],
          createdAt: DateTime(now.year, now.month, now.day, 8, 0),
          updatedAt: DateTime(now.year, now.month, now.day, 10, 30),
        ),
      ];

      for (final session in sessions) {
        await _sessionsCollection.doc(session.id).set(session.toMap());
      }

      print('Dummy data created successfully for user: $email');
    } catch (e) {
      throw Exception('Failed to create dummy data: $e');
    }
  }

  // Get or create student with dummy data
  Future<Student?> getOrCreateStudentByEmail(
    String email,
    String displayName,
  ) async {
    try {
      print('🔄 Getting or creating student for email: $email');
      // Try to get existing student
      Student? student = await getStudentByEmail(email);

      if (student == null) {
        print('🏗️ Student not found, creating dummy data for: $email');
        // Create dummy data for new user
        await createDummyDataForUser(email, displayName);
        // Get the newly created student
        student = await getStudentByEmail(email);

        if (student != null) {
          print(
            '✅ Successfully created and retrieved student: ${student.name}',
          );
        } else {
          print('❌ Failed to retrieve student after creation');
        }
      } else {
        print('✅ Found existing student: ${student.name}');
      }

      return student;
    } catch (e) {
      throw Exception('Failed to get or create student: $e');
    }
  }
}
