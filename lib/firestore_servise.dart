import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendence/main.dart'; // Subject model

class FirestoreService {

  // 🔥 THIS WAS MISSING — DEFINE IT
  static CollectionReference<Subject> _userAttendanceRef() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .withConverter<Subject>(
          fromFirestore: (snapshot, _) =>
              Subject.fromJson(snapshot.data()!, docId: snapshot.id),
          toFirestore: (subject, _) => subject.toJson(),
        );
  }

  // ===============================
  // CREATE
  // ===============================
  static Future<void> addSubject(Subject subject) async {
  print('🔥 ADD SUBJECT CALLED');

  final docRef = await _userAttendanceRef().add(subject);

  subject.docId = docRef.id;
  print('✅ SUBJECT ADDED WITH ID: ${docRef.id}');
}


  // ===============================
  // READ
  // ===============================
  static Future<List<Subject>> getSubjects() async {
    final snapshot = await _userAttendanceRef().get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  static Stream<List<Subject>> streamSubjects() {
    return _userAttendanceRef()
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ===============================
  // UPDATE
  // ===============================
  static Future<void> updateSubject(Subject subject) async {
    if (subject.docId == null) return;

    await _userAttendanceRef().doc(subject.docId).update({
      'present': subject.present,
      'absent': subject.absent,
    });
  }

  // ===============================
  // DELETE
  // ===============================
  static Future<void> deleteSubject(Subject subject) async {
    if (subject.docId == null) return;
    await _userAttendanceRef().doc(subject.docId).delete();
  }

  static Future<void> deleteAllSubjects() async {
    final snapshot = await _userAttendanceRef().get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
