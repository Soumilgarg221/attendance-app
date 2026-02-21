import 'package:attendence/attendence_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';




void main() async{
WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);


await FirebaseAuth.instance.signInAnonymously();

  runApp(ChangeNotifierProvider(
    create: (_) => AttendanceProvider(),
    child: const AttendanceApp()));
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({Key? key}) : super(key: key);

  @override
  
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: const AttendanceHomePage(
        
      ),
    );
  }
}

class Subject {
  String? docId;
  String name;
  String? professorName;
  int present;
  int absent;

  Subject({
    this.docId,
    required this.name,
    this.professorName,
    this.present = 0,
    this.absent = 0,
  });

  // 🔹 ADD THIS BACK
  int get totalClasses => present + absent;

  // 🔹 ADD THIS BACK
  double get attendancePercentage {
    final total = totalClasses;
    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'professorName': professorName,
      'present': present,
      'absent': absent,
    };
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return Subject(
      docId: docId,
      name: json['name'],
      professorName: json['professorName'],
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
    );
  }
}




class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({Key? key}) : super(key: key);

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {

@override
void initState() {
  super.initState();

  // 🔥 START FIRESTORE STREAM
  Future.microtask(() {
    context.read<AttendanceProvider>().startListening();
  });
}



  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) {
        String subjectName = '';
        String professorName = '';

        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Add Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => subjectName = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Professor Name (Optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => professorName = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (subjectName.isNotEmpty) {
                  context.read<AttendanceProvider>().addSubject(
                    subjectName,
                    professorName.isEmpty ? null : professorName,
                  );

                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSubject(Subject subject) {
  context.read<AttendanceProvider>().deleteSubject(subject);
}



  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AttendanceProvider>();
    final subjects = provider.subjects;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        centerTitle: true,
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a subject',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return SubjectCard(
                  subject: subjects[index],
                    onDelete: () => provider.deleteSubject(subjects[index]),

                );

              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onDelete;

  const SubjectCard({
    Key? key,
    required this.subject,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percentage = subject.attendancePercentage;
    Color percentageColor = percentage >= 75
        ? Colors.green
        : percentage >= 65
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subject.professorName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subject.professorName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Percentage Display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: percentageColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: percentageColor, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, color: percentageColor),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: percentageColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${subject.present}/${subject.totalClasses})',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Present Counter
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Present',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.green,
                              onPressed: () {
                                if (subject.present > 0) {
                                  context.read<AttendanceProvider>().unmarkPresent(subject);

                                }
                              },
                            ),
                            Text(
                              '${subject.present}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.green,
                              onPressed: () {
                                context.read<AttendanceProvider>().markPresent(subject);

                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Absent Counter
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Absent',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                if (subject.absent > 0) {
                                  context.read<AttendanceProvider>().unmarkAbsent(subject);

                                }
                              },
                            ),
                            Text(
                              '${subject.absent}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Colors.red,
                              onPressed: () {
                                context.read<AttendanceProvider>().markAbsent(subject);

                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}