import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Resolves the signed-in owner's shop before accessing customer documents.
///
/// Customer data is always stored below `shops/{shopId}/customers`; the
/// authenticated user's document is used only to resolve the owning shop ID.
class CustomerRepository {
  CustomerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
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

    return shopId;
  }

  Future<CollectionReference<Map<String, dynamic>>> customerCollection() async {
    final shopId = await currentShopId();
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('customers');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCustomers() async* {
    final customers = await customerCollection();
    yield* customers.orderBy('createdAt', descending: true).snapshots();
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
