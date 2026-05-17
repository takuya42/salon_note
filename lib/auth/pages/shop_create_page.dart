import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../store/pages/reservation_page.dart';

class ShopCreatePage extends StatefulWidget {
  const ShopCreatePage({super.key});

  @override
  State<ShopCreatePage> createState() => _ShopCreatePageState();
}

class _ShopCreatePageState extends State<ShopCreatePage> {

  final nameController = TextEditingController();
  bool isLoading = false;

  /// 🔥 店舗作成
  Future<void> createShop() async {

    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("店舗名を入力してください")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("ログイン状態がありません");

      final shopId = const Uuid().v4();

      /// 店舗作成
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .set({
        'shopId': shopId,
        'name': name,
        'ownerId': user.uid,
        'ownerEmail': user.email,
        'createdAt': Timestamp.now(),
      });
      /// ユーザー紐付け
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'shopId': shopId,
        'role': 'store',
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("店舗登録完了🔥")),
        );
      }

      /// 画面遷移
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ReservationPage(),
          ),
              (route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("エラー: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("店舗登録"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "あなたの店舗を登録しましょう",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "この情報は後から変更できます",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              /// 店舗名入力
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "店舗名",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// 🔥 登録ボタン（ダイアログ付き）
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {

                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("確認"),
                          content: Text(
                            "「${nameController.text.trim()}」を登録しますか？",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("キャンセル"),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text(
                                "登録",
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (result == true) {
                      await createShop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "登録する",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}