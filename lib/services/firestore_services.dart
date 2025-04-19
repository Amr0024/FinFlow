import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ──────────────────────────── raw streams (existing) ────────────────────────────
  static Stream<DocumentSnapshot<Map<String, dynamic>>> balanceStream() =>
      _db
          .collection('users')
          .doc(_uid)
          .collection('balance')
          .doc('current')
          .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> categoryStream() =>
      _db
          .collection('users')
          .doc(_uid)
          .collection('categories')
          .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> recentTxStream(int limit) =>
      _db
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();

  // ──────────────────────────── PUBLIC WRAPPERS (NEW) ────────────────────────────
  ///Categories as a List<Map<String,dynamic>>`
  static Stream<List<Map<String, dynamic>>> streamCategories() =>
      categoryStream()
          .map((snap) => snap.docs.map(_catFromDoc).toList());

  ///Balance as a simple `Map<String,dynamic>` (or `{}` if not yet created)
  static Stream<Map<String, dynamic>> streamBalance() =>
      balanceStream()
          .map((doc) => doc.data() ?? {});

  ///Last20 transactions, already converted to `Map`s
  static Stream<List<Map<String, dynamic>>> streamRecentTransactions() =>
      recentTxStream(20)
          .map((snap) => snap.docs.map((d) => d.data()).toList());

  // Helper: rebuild Color / IconData from the primitive ints we store
  static Map<String, dynamic> _catFromDoc(
      DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!..addAll({'id': d.id});
    m['icon']  = IconData(m['icon'], fontFamily: 'MaterialIcons');
    m['color'] = Color(m['color']);
    return m;
  }

  static Future<void> initNewUser({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final userDoc = _db.collection('users').doc(_uid);

    // create sub‑collection docs inside a single batch
    final batch = _db.batch();

    // user profile (top‑level)
    batch.set(userDoc, {
      'firstName': firstName,
      'lastName' : lastName,
      'email'    : email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // balance/current
    batch.set(userDoc.collection('balance').doc('current'), {
      'total'        : 0.0,
      'monthlyBudget': 0.0,
    });

    // some default categories
    const defaults = [
      {'name':'Food',          'icon': 0xe57a, 'color': 0xFFe91e63},
      {'name':'Entertainment', 'icon': 0xe8a3, 'color': 0xFF9c27b0},
      {'name':'Fashion',       'icon': 0xe41d, 'color': 0xFF2196f3},
    ];
    for (final cat in defaults) {
      final doc = userDoc.collection('categories').doc();
      batch.set(doc, {
        'name'  : cat['name'],
        'icon'  : cat['icon'],
        'color' : cat['color'],
        'budget': 0.0,
      });
    }
  }

  static Future<void> addCategory({
    required String name,
    required int color,
    required int icon,
  }) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('categories')
        .add({
      'name': name,
      'color': color,   // store primitive int (Color.value)
      'icon': icon,     // store codePoint int (IconData.codePoint)
      'budget': 0.0,
    });
  }

  ///`amount>0= incomeamount<0= expense
  static Future<void> addTransaction({
    required String? catId,
    required double amount,
    bool   notPriority = false,
    String? productName,
  }) async {
    final userDoc = _db.collection('users').doc(_uid);
    final batch   = _db.batch();

    // 1)transaction row
    final txRef = userDoc.collection('transactions').doc();
    batch.set(txRef, {
      'catId'       : catId,
      'amount'      : amount,
      'createdAt'   : FieldValue.serverTimestamp(),
      'notPriority' : notPriority,
      'productName' : productName,
    });

    // 2)running balance
    batch.update(userDoc.collection('balance').doc('current'), {
      'total'         : FieldValue.increment(amount),
      'monthlyBudget' : FieldValue.increment(amount),
    });

    // 3-category budget (expenses only & catId not null)
    if (catId != null && amount < 0) {
      batch.update(
        userDoc.collection('categories').doc(catId),
        {
          // amount is negative, we subtract its absolute value
          'budget': FieldValue.increment(amount.abs() * -1),
        },
      );
    }

    await batch.commit();
  }
}