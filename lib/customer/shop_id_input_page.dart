import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer_booking_page.dart';

class ShopIdInputPage extends StatefulWidget {
  const ShopIdInputPage({super.key});

  @override
  State<ShopIdInputPage> createState() => _ShopIdInputPageState();
}

class _ShopIdInputPageState extends State<ShopIdInputPage> {

  final controller = TextEditingController();

  String? shopName;
  bool isLoading = false;

  /// 🔥 店舗検索
  Future<void> searchShop() async {

    final shopId = controller.text.trim().toLowerCase();

    if (shopId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("店舗IDを入力してください")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      shopName = null;
    });

    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .get();

    if (!doc.exists) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("店舗が見つかりません")),
      );
      return;
    }

    setState(() {
      shopName = doc.data()?['name'];
      isLoading = false;
    });
  }

  /// 🔥 予約画面へ
  void goToBooking() {

    final shopId = controller.text.trim().toLowerCase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerBookingPage(
          shopId: shopId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔥 AppBar = 検索バー
      appBar: AppBar(
        backgroundColor: Colors.orange,

        title: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),

          decoration: const InputDecoration(
            hintText: "店舗IDを入力（例: nail01）",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),

          /// 🔥 小文字固定
          onChanged: (value) {
            controller.value = TextEditingValue(
              text: value.toLowerCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          },

          /// 🔥 Enterで検索
          onSubmitted: (_) => searchShop(),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: searchShop,
          ),
        ],
      ),

      /// 🔥 Body
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const SizedBox(height: 20),

            /// 🔥 ローディング
            if (isLoading)
              const CircularProgressIndicator(),

            /// 🔥 店舗表示
            if (shopName != null) ...[

              Text(
                shopName!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "ID: ${controller.text}",
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: goToBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("この店舗で予約する"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}