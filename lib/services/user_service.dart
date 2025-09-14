import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService._internal();
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _users => _firestore.collection('users');

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }

  Future<void> upsertUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
