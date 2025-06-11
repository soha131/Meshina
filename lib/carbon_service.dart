import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarbonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
/*
  Future<void> addEcoPointsToUser(int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);

      if (!snapshot.exists) {
        transaction.set(userDoc, {'totalEcoPoints': points});
      } else {
        final currentPoints = snapshot['totalEcoPoints'] ?? 0;
        transaction.update(userDoc, {'totalEcoPoints': currentPoints + points});
      }
    });
  }*/

  Future<int> getEcoPointsForUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data()?['totalEcoPoints'] ?? 0;
  }
}
