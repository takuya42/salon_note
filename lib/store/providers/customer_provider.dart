import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';

final customerProvider =
StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier() : super([]) {
    listenCustomers();
  }

  final _db = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// 🔥 リアルタイム
  void listenCustomers() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      state = [];
      return;
    }

    _db
        .collection('users')
        .doc(user.uid)
        .collection('customers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data();

        return Customer(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          memo: data['memo'] ?? '',
          sales: [],
        );
      }).toList();
    });
  }

  /// 🔥 追加（旧コード用）
  Future<void> addCustomer(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('customers')
        .add({
      'name': name,
      'memo': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔥 追加（予約用）
  Future<void> addCustomerFull({
    required String name,
    required String email,
    required String phone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('customers')
        .add({
      'name': name,
      'email': email,
      'phone': phone,
      'memo': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔥 削除
  Future<void> deleteCustomer(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('customers')
        .doc(id)
        .delete();
  }

  /// 🔥 メモ更新（これないとエラー出る）
  Future<void> updateMemo(String id, String memo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('customers')
        .doc(id)
        .update({
      'memo': memo,
    });
  }
}