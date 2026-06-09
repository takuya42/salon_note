import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customerDetailProvider = StreamProvider.autoDispose
    .family<CustomerDetailData?, String>((ref, customerId) {
  return ref.watch(customerRepositoryProvider).watchCustomerDetail(customerId);
});

final customerProvider =
    StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  CustomerNotifier({CustomerRepository? repository})
      : _repository = repository ?? CustomerRepository(),
        super([]) {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _customerSubscription?.cancel();
      _customerSubscription = null;
      state = [];
      if (user != null) {
        _listenCustomers();
      }
    });
  }

  final CustomerRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _customerSubscription;

  void _listenCustomers() {
    _customerSubscription = _repository.watchCustomers().listen(
      (snapshot) {
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
      },
      onError: (_) => state = [],
    );
  }

  Future<int> customerCount() => _repository.customerCount();

  Future<void> addCustomer(String name) async {
    await _repository.addCustomer(name: name);
    await FirebaseAnalytics.instance.logEvent(name: 'customer_added');
  }

  Future<void> addCustomerFull({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _repository.addCustomer(name: name, email: email, phone: phone);
    await FirebaseAnalytics.instance.logEvent(name: 'customer_added');
  }

  Future<void> updateCustomer(
    String id, {
    required String name,
    required String email,
    required String phone,
  }) {
    return _repository.updateCustomer(
      id,
      name: name,
      email: email,
      phone: phone,
    );
  }

  Future<void> deleteCustomer(String id) => _repository.deleteCustomer(id);

  Future<void> updateMemo(String id, String memo) {
    return _repository.updateMemo(id, memo);
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
