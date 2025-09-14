import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart' as session_model;

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _sessionsCol => _firestore.collection('sessions');
  CollectionReference get _sessionCol => _firestore.collection('session');

  // Fetch all sessions. Optionally filter by status, subject, or faculty.
  Future<List<session_model.Session>> fetchSessions({
    String? status, // 'scheduled' | 'active' | 'completed' | 'cancelled'
    String? subjectId,
    String? facultyName,
  }) async {
    // Try primary collection 'sessions' first
    Query query = _sessionsCol.orderBy('startTime', descending: false);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (subjectId != null) {
      query = query.where('subjectId', isEqualTo: subjectId);
    }
    if (facultyName != null) {
      query = query.where('facultyName', isEqualTo: facultyName);
    }

    final primary = await query.get();
    if (primary.docs.isNotEmpty) {
      return primary.docs.map((d) => _sessionFromDoc(d)).toList();
    }

    // Fallback to alternate collection 'session' (singular)
    Query alt = _sessionCol.orderBy('startTime', descending: false);
    if (subjectId != null) {
      alt = alt.where('classId', isEqualTo: subjectId);
    }
    final altSnap = await alt.get();
    final all = altSnap.docs.map((d) => _sessionFromDoc(d)).toList();

    // Apply remaining filters in-memory to accommodate schema differences
    var filtered = all;
    if (status != null) {
      filtered = filtered.where((s) => s.status == status).toList();
    }
    if (facultyName != null) {
      filtered = filtered.where((s) => s.facultyName == facultyName).toList();
    }
    return filtered;
  }

  // Fetch active sessions only
  Future<List<session_model.Session>> fetchActiveSessions() async {
    final snapshot = await _sessionsCol
        .where('status', isEqualTo: 'active')
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => _sessionFromDoc(doc)).toList();
    }
    // Fallback to singular collection using isActive flag
    final alt = await _sessionCol.where('isActive', isEqualTo: true).get();
    return alt.docs.map((doc) => _sessionFromDoc(doc)).toList();
  }

  // Mark attendance as present by adding the studentId to attendedStudents array
  Future<void> markPresent({
    required String sessionId,
    required String studentId,
  }) async {
    // Try 'sessions' then fallback to 'session'
    DocumentReference docRef = _sessionsCol.doc(sessionId);
    var snap = await docRef.get();
    if (!snap.exists) {
      docRef = _sessionCol.doc(sessionId);
      snap = await docRef.get();
      if (!snap.exists) {
        throw Exception('Session not found');
      }
    }
    final data = snap.data() as Map<String, dynamic>;

    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final bool hasIsActive = data.containsKey('isActive');
    final bool isActiveFlag = data['isActive'] == true;
    final String status =
        (data['status'] ?? (isActiveFlag ? 'active' : 'scheduled')) as String;

    DateTime? start;
    DateTime? end;
    try {
      if (data['startTime'] != null) start = _toDate(data['startTime']);
      if (data['endTime'] != null) end = _toDate(data['endTime']);
    } catch (_) {
      start = null;
      end = null;
    }
    final now = DateTime.now();
    bool withinWindow = true;
    if (start != null && end != null) {
      withinWindow = now.isAfter(start) && now.isBefore(end);
    }

    if (hasIsActive) {
      if (!isActiveFlag) {
        throw Exception('Session is not active');
      }
    } else {
      if (status != 'active' || !withinWindow) {
        throw Exception('Session is not active');
      }
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
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return session_model.Session(
      id: doc.id,
      subjectId: (data['subjectId'] ?? data['classId'] ?? '') as String,
      subjectName: (data['subjectName'] ?? data['className'] ?? '') as String,
      facultyName: (data['facultyName'] ?? data['facultyId'] ?? '') as String,
      startTime: _toDate(data['startTime']),
      endTime: _toDate(data['endTime']),
      status:
          (data['status'] ??
                  (data['isActive'] == true ? 'active' : 'scheduled'))
              as String,
      location: (data['location'] ?? '') as String,
      attendedStudents: List<String>.from(data['attendedStudents'] ?? const []),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }
}
