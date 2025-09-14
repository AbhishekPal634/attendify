import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart' as session_model;

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _sessionCol => _firestore.collection('session');

  // Fetch all sessions from 'session'. Optionally filter by status, subject, or faculty.
  Future<List<session_model.Session>> fetchSessions({
    String? status, // 'scheduled' | 'active' | 'completed' | 'cancelled'
    String? subjectId,
    String? facultyName,
  }) async {
    Query query = _sessionCol.orderBy('startTime', descending: false);
    // Support either 'subjectId' or schema's 'classId' field
    if (subjectId != null) {
      // First try subjectId; if schema uses classId this will be filtered in-memory
      query = query.where('classId', isEqualTo: subjectId);
    }
    final snap = await query.get();
    var list = snap.docs.map((d) => _sessionFromDoc(d)).toList();
    // Apply optional filters in-memory due to schema differences
    if (status != null) {
      list = list.where((s) => s.status == status).toList();
    }
    if (facultyName != null) {
      list = list.where((s) => s.facultyName == facultyName).toList();
    }
    if (subjectId != null) {
      list = list.where((s) => s.subjectId == subjectId).toList();
    }
    return list;
  }

  // Fetch active sessions only
  Future<List<session_model.Session>> fetchActiveSessions() async {
    // Load from 'session' and filter by time window
    final now = DateTime.now();
    final snap = await _sessionCol.get();
    final sessions = snap.docs.map((d) => _sessionFromDoc(d)).toList();
    return sessions
        .where((s) => now.isAfter(s.startTime) && now.isBefore(s.endTime))
        .toList();
  }

  // Fetch upcoming sessions (startTime > from). Defaults to now; optional limit.
  Future<List<session_model.Session>> fetchUpcomingSessions({
    DateTime? from,
    int? limit,
  }) async {
    final DateTime startAfter = (from ?? DateTime.now()).toUtc();
    // Firestore expects Timestamp for range; store as Timestamp via milliseconds
    Query query = _sessionCol
        .orderBy('startTime')
        .where('startTime', isGreaterThan: Timestamp.fromDate(startAfter));
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    final snap = await query.get();
    final sessions = snap.docs.map((d) => _sessionFromDoc(d)).toList();
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  // Mark attendance as present by adding the studentId to attendedStudents array
  Future<void> markPresent({
    required String sessionId,
    required String studentId,
  }) async {
    // Use only 'session' collection
    final DocumentReference docRef = _sessionCol.doc(sessionId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw Exception('Session not found');
    }
    final data = snap.data() as Map<String, dynamic>;

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate().toLocal();
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        return (parsed?.toLocal()) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // Validate strictly by time window regardless of any 'isActive' flag or 'status'
    DateTime? start;
    DateTime? end;
    try {
      if (data['startTime'] != null) start = _toDate(data['startTime']);
      if (data['endTime'] != null) end = _toDate(data['endTime']);
    } catch (_) {
      start = null;
      end = null;
    }
    if (start == null || end == null) {
      throw Exception('Session time not configured');
    }
    final now = DateTime.now();
    final withinWindow = now.isAfter(start) && now.isBefore(end);
    if (!withinWindow) {
      throw Exception('Session is not active');
    }

    final List<dynamic> attended = (data['attendedStudents'] ?? []) as List;
    if (attended.contains(studentId)) {
      // Already marked present, no-op
      return;
    }

    await docRef.update({
      'attendedStudents': FieldValue.arrayUnion([studentId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Internal: map Firestore doc to Session model accommodating Timestamp or String
  session_model.Session _sessionFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate().toLocal();
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        return (parsed?.toLocal()) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return session_model.Session(
      id: doc.id,
      subjectId: (data['subjectId'] ?? data['classId'] ?? '') as String,
      subjectName: (data['subjectName'] ?? data['className'] ?? '') as String,
      facultyName: (data['facultyName'] ?? data['facultyId'] ?? '') as String,
      startTime: _toDate(data['startTime']),
      endTime: _toDate(data['endTime']),
      status: (data['status'] ?? 'scheduled') as String,
      location: (data['location'] ?? '') as String,
      attendedStudents: List<String>.from(data['attendedStudents'] ?? const []),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }
}
