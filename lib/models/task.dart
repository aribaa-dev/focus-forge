import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String subject;
  final String title;
  final DateTime dueDate;
  final String dueTime;
  final int estimatedMinutes;
  final int studiedSeconds;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.createdAt,
    required this.dueTime,
    required this.estimatedMinutes,
    required this.isCompleted,
    required this.studiedSeconds,
  });

  double get progress {
    if (estimatedMinutes <= 0) return 0.0;
    final ratio = studiedSeconds / (estimatedMinutes * 60);
    return ratio.clamp(0.0, 1.0);
  }

  String get duration => '${estimatedMinutes}m';

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'dueDate': Timestamp.fromDate(dueDate),
      'dueTime': dueTime,
      'estimatedMinutes': estimatedMinutes,
      'studiedSeconds': studiedSeconds,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      dueTime: map['dueTime'] ?? '',
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
      studiedSeconds: map['studiedSeconds'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task.fromMap(data, doc.id);
  }

  Task copyWith({int? studiedSeconds, bool? isCompleted}) {
    return Task(
      id: id,
      title: title,
      subject: subject,
      dueDate: dueDate,
      dueTime: dueTime,
      estimatedMinutes: estimatedMinutes,
      studiedSeconds: studiedSeconds ?? this.studiedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
