import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_study/models/task.dart';

class FirestoreService {
  final CollectionReference _collectionReference = FirebaseFirestore.instance
      .collection('tasks');

  Future<void> addTask(Task task) async {
    await _collectionReference.add(task.toMap());
  }

  Stream<List<Task>> getTasksStream() {
    return _collectionReference
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList(),
        );
  }

  // TaskDetail will call this to load one task
  Future<Task> getTaskById(String taskId) async {
    final doc = await _collectionReference.doc(taskId).get();
    return Task.fromFirestore(doc);
  }

  Future<void> updateStudiedSeconds(String taskId, int newTotalSeconds) async {
    await _collectionReference.doc(taskId).update({
      'studiedSeconds': newTotalSeconds,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _collectionReference.doc(taskId).delete();
  }
}
