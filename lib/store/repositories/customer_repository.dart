import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';

class CustomerDetailData {
  const CustomerDetailData({required this.customer, required this.sales});

  final Customer customer;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> sales;
}

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> currentShopId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('顧客情報を利用するにはログインが必要です。');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final shopId = userDoc.data()?['shopId'];
    if (shopId is! String || shopId.trim().isEmpty) {
      throw StateError('店舗情報が見つかりません。');
    }

    return shopId.trim();
  }

  Future<CollectionReference<Map<String, dynamic>>> customerCollection() async {
    final shopId = await currentShopId();
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('customers');
  }

  Future<CollectionReference<Map<String, dynamic>>> salesCollection() async {
    final shopId = await currentShopId();
    return _firestore.collection('shops').doc(shopId).collection('sales');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomers() async* {
    final customers = await customerCollection();
    yield* customers.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<CustomerDetailData?> watchCustomerDetail(String customerId) {
    late final StreamController<CustomerDetailData?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? customerSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? salesSub;
    DocumentSnapshot<Map<String, dynamic>>? latestCustomer;
    QuerySnapshot<Map<String, dynamic>>? latestSales;

    void emitWhenReady() {
      final customerSnapshot = latestCustomer;
      final salesSnapshot = latestSales;
      if (customerSnapshot == null || salesSnapshot == null) return;
      if (!customerSnapshot.exists || customerSnapshot.data() == null) {
        controller.add(null);
        return;
      }

      final data = customerSnapshot.data()!;
      controller.add(
        CustomerDetailData(
          customer: Customer(
            id: customerSnapshot.id,
            name: data['name'] as String? ?? '',
            email: data['email'] as String? ?? '',
            phone: data['phone'] as String? ?? '',
            memo: data['memo'] as String? ?? '',
            imageUrls: (data['imageUrls'] as List?)
                ?.map((value) => value.toString())
                .toList(),
          ),
          sales: [...salesSnapshot.docs]
            ..sort((a, b) {
              final aDate = a.data()['date'];
              final bDate = b.data()['date'];
              if (aDate is! Timestamp || bDate is! Timestamp) return 0;
              return bDate.compareTo(aDate);
            }),
        ),
      );
    }

    controller = StreamController<CustomerDetailData?>(
      onListen: () async {
        try {
          final customers = await customerCollection();
          final sales = await salesCollection();
          if (controller.isClosed) return;

          customerSub = customers.doc(customerId).snapshots().listen(
            (snapshot) {
              latestCustomer = snapshot;
              emitWhenReady();
            },
            onError: controller.addError,
          );
          salesSub = sales
              .where('customerId', isEqualTo: customerId)
              .snapshots()
              .listen(
            (snapshot) {
              latestSales = snapshot;
              emitWhenReady();
            },
            onError: controller.addError,
          );
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      },
      onCancel: () async {
        await customerSub?.cancel();
        await salesSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<int> customerCount() async {
    final customers = await customerCollection();
    final snapshot = await customers.get();
    return snapshot.docs.length;
  }

  Future<void> addCustomer({
    required String name,
    String email = '',
    String phone = '',
  }) async {
    final customers = await customerCollection();
    await customers.add({
      'name': name,
      'email': email,
      'phone': phone,
      'memo': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCustomer(
    String id, {
    required String name,
    required String email,
    required String phone,
  }) async {
    final customers = await customerCollection();
    await customers.doc(id).update({
      'name': name,
      'email': email,
      'phone': phone,
    });
  }

  Future<void> updateMemo(String id, String memo) async {
    final customers = await customerCollection();
    await customers.doc(id).update({'memo': memo});
  }

  Future<void> deleteCustomer(String id) async {
    final customers = await customerCollection();
    await customers.doc(id).delete();
  }
}
