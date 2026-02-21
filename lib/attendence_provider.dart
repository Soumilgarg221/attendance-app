import 'package:flutter/material.dart';
import 'package:attendence/firestore_servise.dart';

import 'main.dart'; // for Subject model
import 'dart:async';


class AttendanceProvider extends ChangeNotifier {
  final List<Subject> _subjects = [];
  StreamSubscription<List<Subject>>? _sub;

  List<Subject> get subjects => _subjects;

  // ==========================
  // START FIRESTORE LISTENER
  // ==========================
  void startListening() {
    _sub?.cancel();

    _sub = FirestoreService.streamSubjects().listen((subjects) {
      _subjects
        ..clear()
        ..addAll(subjects);
      notifyListeners();
    });
  }

  // ==========================
  // CREATE
  // ==========================
  Future<void> addSubject(String name, String? professor) async {
    final subject = Subject(
      name: name,
      professorName: professor,
    );

    // ❌ DO NOT touch _subjects here
    await FirestoreService.addSubject(subject);
  }

  // ==========================
  // DELETE
  // ==========================
  Future<void> deleteSubject(Subject subject) async {
    await FirestoreService.deleteSubject(subject);
  }

  // ==========================
  // UPDATE
  // ==========================
  void markPresent(Subject subject) {
    subject.present++;
    FirestoreService.updateSubject(subject);
  }

  void unmarkPresent(Subject subject) {
    if (subject.present > 0) {
      subject.present--;
      FirestoreService.updateSubject(subject);
    }
  }

  void markAbsent(Subject subject) {
    subject.absent++;
    FirestoreService.updateSubject(subject);
  }

  void unmarkAbsent(Subject subject) {
    if (subject.absent > 0) {
      subject.absent--;
      FirestoreService.updateSubject(subject);
    }
  }

  // ==========================
  // CLEANUP
  // ==========================
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
