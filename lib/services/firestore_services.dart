import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ---------- live streams ----------
  static Stream<DocumentSnapshot<Map<String, dynamic>>> balanceStream() =>
      _db.collection('users').doc(_uid).collection('balance').doc('current').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> categoryStream() =>
      _db.collection('users').doc(_uid).collection('categories').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> recentTxStream(int limit) =>
      _db.collection('users')
          .doc(_uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();

  // ---------- writes ----------
  static Future<void> addCategory({
    required String name,
    required int color,
    required int icon,
  }) async {
    await _db.collection('users').doc(_uid).collection('categories').add({
      'name': name,
      'color': color,
      'icon': icon,
      'budget': 0.0,
    });
  }

  /// amount > 0  = income,  amount < 0  = expense
  static Future<void> addTransaction({
    required String? catId,
    required double amount,
    bool notPriority = false,
    String? productName,
  }) async {
    final userDoc = _db.collection('users').doc(_uid);
    final batch   = _db.batch();

    // 1) add transaction
    final txRef = userDoc.collection('transactions').doc();
    batch.set(txRef, {
      'catId'       : catId,
      'amount'      : amount,
      'createdAt'   : FieldValue.serverTimestamp(),
      'notPriority' : notPriority,
      'productName' : productName,
    });

    // 2) update running balance
    batch.update(userDoc.collection('balance').doc('current'), {
      'total'        : FieldValue.increment(amount),
      'monthlyBudget': FieldValue.increment(amount),
    });

    // 3) subtract from category budget (expenses only)
    if (catId != null && amount < 0) {
      batch.update(
        userDoc.collection('categories').doc(catId),
        {'budget': FieldValue.increment(amount.abs() * -1)},
      );
    }

    await batch.commit();
  }
}
