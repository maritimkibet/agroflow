import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_task.dart';

class FirestoreService {
  final _taskCollection = FirebaseFirestore.instance.collection('crop_tasks');

  Future<void> addOrUpdateTask(CropTask task) async {
    await _taskCollection.doc(task.id).set(task.toJson());
  }

  Stream<List<CropTask>> getTasksStream() {
    return _taskCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CropTask.fromJson(doc.data())).toList());
  }

  Future<void> deleteTask(String id) async {
    await _taskCollection.doc(id).delete();
  }
}
