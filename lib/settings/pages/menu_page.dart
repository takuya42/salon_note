import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String? get uid => FirebaseAuth.instance.currentUser?.uid;

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  Future<String?> _getShopId() async {
    if (uid == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return userDoc.data()?['shopId'];
  }

  Future<void> addMenu() async {
    final shopId = await _getShopId();

    if (shopId == null) return;
    if (nameController.text.isEmpty || priceController.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('menus')
        .add({
      'name': nameController.text.trim(),
      'price': int.tryParse(priceController.text.trim()) ?? 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    nameController.clear();
    priceController.clear();
  }

  Future<void> deleteMenu(String id) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('menus')
        .doc(id)
        .delete();
  }

  Stream<QuerySnapshot> menuStream() async* {
    final shopId = await _getShopId();

    if (shopId == null) {
      yield* const Stream.empty();
      return;
    }

    yield* FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('menus')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("メニュー管理"),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "メニュー名",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "料金（円）",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: addMenu,
                  child: const Text("追加"),
                ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: menuStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("メニューがありません"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text("¥${data['price']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteMenu(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}