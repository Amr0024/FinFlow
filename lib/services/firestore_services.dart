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

  static Stream<QuerySnapshot<Map<String, dynamic>>> recentTxStream(
      int limit) =>
      _db
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();

  // ──────────────────────────── PUBLIC WRAPPERS (NEW) ────────────────────────────
  ///Categories as a List
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
    final m = d.data()!
      ..addAll({'id': d.id});
    m['icon'] = IconData(m['icon'], fontFamily: 'MaterialIcons');
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
      'lastName': lastName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // balance/current
    batch.set(userDoc.collection('balance').doc('current'), {
      'total': 0.0,
      'monthlyBudgetLeft': 0.0,
      'monthlyBudgetTarget': 0.0,
      'spent': 0.0
    });

    // some default categories
    const defaults = [
      {'name': 'Food', 'icon': 0xe57a, 'color': 0xFFe91e63},
      {'name': 'Entertainment', 'icon': 0xe8a3, 'color': 0xFF9c27b0},
      {'name': 'Fashion', 'icon': 0xe41d, 'color': 0xFF2196f3},
    ];
    for (final cat in defaults) {
      final doc = userDoc.collection('categories').doc();
      batch.set(doc, {
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'budget': 0.0,
      });
    }
  }

  static Future<void> setBalance({
    required double total,
    required double monthlyBudgetLeft,
    required double monthlyBudgetTarget,
    required spent,
  }) {
    final balRef = _db
        .collection('users')
        .doc(_uid)
        .collection('balance')
        .doc('current');

    return balRef.set({
      'total' : total,
      'monthlyBudgetLeft': monthlyBudgetLeft,
      'monthlyBudgetTarget': monthlyBudgetLeft,
      'spent': spent,
    }, SetOptions(merge: true));
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
      'color': color,
      'icon': icon,
      'budget': 0.0,
    });
  }

  ///amount>0= income amount<0= expense
  static Future<void> addTransaction({
    required String? catId,
    required double amount, // + = income,  – = expense
    bool notPriority = false,
    String? productName,
  }) async {
    final userDoc = _db.collection('users').doc(_uid);
    final batch = _db.batch();

    // 1) transaction record
    final txRef = userDoc.collection('transactions').doc();
    batch.set(txRef, {
      'catId': catId,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
      'notPriority': notPriority,
      'productName': productName,
    });

    // 2) running balance
    final balRef = userDoc.collection('balance').doc('current');
    batch.set(balRef, { // set‑with‑merge ⇒ creates if absent
      'monthlyBudgetLeft': FieldValue.increment(amount),
    }, SetOptions(merge: true));

    // 3) category budget
    if (catId != null && amount < 0) {
      final catRef = userDoc.collection('categories').doc(catId);
      batch.set(catRef, { // create if missing
        'budget': FieldValue.increment(amount.abs()),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ──────────────────────────── FINANCIAL GOALS ────────────────────────────
  static Future<List<Map<String, dynamic>>> getFinancialGoals() async {
    final doc = await _db.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};
    final goals = data['financialGoals'] as List<dynamic>?;
    if (goals == null) return [];
    return goals.map((g) => Map<String, dynamic>.from(g)).toList();
  }

  static Future<void> setFinancialGoals(List<Map<String, dynamic>> goals) async {
    await _db.collection('users').doc(_uid).set({
      'financialGoals': goals,
    }, SetOptions(merge: true));
  }

  // ──────────────────────────── SAVINGS ────────────────────────────
  static Future<void> addSavings({
    required String goal,
    required double amount,
    required DateTime date,
  }) async {
    await _db.collection('users').doc(_uid).collection('savings').add({
      'goal': goal,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    });
  }

  static Future<List<Map<String, dynamic>>> getSavings({String? goal}) async {
    Query query = _db.collection('users').doc(_uid).collection('savings');
    if (goal != null) {
      query = query.where('goal', isEqualTo: goal);
    }
    final snap = await query.get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  // ──────────────────────────── SAVINGS CHART (for line chart) ────────────────────────────
  static Future<List<Map<String, dynamic>>> getSavingsChartData() async {
    final snap = await _db.collection('users').doc(_uid).collection('savings_chart').orderBy('month').get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  static Future<void> setSavingsChartData(List<Map<String, dynamic>> data) async {
    final batch = _db.batch();
    final col = _db.collection('users').doc(_uid).collection('savings_chart');
    final docs = await col.get();
    // Delete old docs
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    // Add new data
    for (final entry in data) {
      batch.set(col.doc(), entry);
    }
    await batch.commit();
  }
}