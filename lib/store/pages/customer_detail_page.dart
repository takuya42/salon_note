import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';
import '../providers/customer_provider.dart';


class CustomerDetailPage extends ConsumerStatefulWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}
const primaryColor = Color(0xFFD8C2B9);
const darkBrown = Color(0xFF5B463C);
const backgroundColor = Color(0xFFFCFCFC);

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();

    final c = widget.customer;

    nameController = TextEditingController(text: c.name);

    emailController = TextEditingController(text: c.email);

    phoneController = TextEditingController(text: c.phone);

    memoController = TextEditingController(text: c.memo);
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);

    final currentCustomer = customers.firstWhere(
      (c) => c.id == widget.customer.id,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darkBrown,
        elevation: 0,

        title: const Text(
          "顧客カルテ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sales')
            .where('customerId', isEqualTo: currentCustomer.id)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final salesDocs = snapshot.data!.docs;

          /// 来店回数
          final visitCount = salesDocs.length;

          /// 合計売上
          int totalSales = 0;

          for (var doc in salesDocs) {
            totalSales += (doc['price'] ?? 0) as int;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// 🔥プロフィール
                Center(
                  child: Column(
                    children: [


                      const SizedBox(height: 12),

                      Text(
                        currentCustomer.name,

                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.22),

                          borderRadius: BorderRadius.circular(30),
                        ),

                        child: Text(
                          "来店回数：$visitCount回",

                          style: const TextStyle(
                            color: darkBrown,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔥基本情報
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFD),

                    borderRadius: BorderRadius.circular(22),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),

                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "基本情報",

                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: nameController,

                        decoration: InputDecoration(
                          labelText: "名前",

                          filled: true,
                          fillColor: primaryColor.withOpacity(0.08),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: emailController,

                        decoration: InputDecoration(
                          labelText: "メールアドレス",

                          filled: true,
                          fillColor: primaryColor.withOpacity(0.08),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: phoneController,

                        decoration: InputDecoration(
                          labelText: "電話番号",

                          filled: true,
                          fillColor: primaryColor.withOpacity(0.08),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(vertical: 16),

                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.16),

                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Text(
                          "合計売上：¥$totalSales",

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                              color: darkBrown,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,

                            foregroundColor: darkBrown,

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          onPressed: () async {
                            await ref
                                .read(customerProvider.notifier)
                                .updateCustomer(
                                  currentCustomer.id,
                                  name: nameController.text,
                                  email: emailController.text,
                                  phone: phoneController.text,
                                );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("基本情報を保存しました")),
                            );
                          },

                          child: const Text(
                            "基本情報を保存",

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                /// 🔥施術写真
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFD),

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          const Text(
                            "施術写真",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              foregroundColor: darkBrown,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            onPressed: null,

                            icon: const Icon(
                              Icons.add_a_photo,
                              size: 18,
                            ),

                            label: const Text(
                              "開発中",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      Container(
                        height: 120,
                        width: double.infinity,

                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),

                          borderRadius: BorderRadius.circular(18),

                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [

                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "施術写真機能は現在開発中です",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                /// 🔥カルテメモ
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFD),

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),

                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "カルテメモ",

                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: memoController,
                        maxLines: 6,

                        decoration: InputDecoration(
                          hintText: "施術内容・会話内容・注意事項など",

                          filled: true,
                          fillColor: primaryColor.withOpacity(0.08),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,

                            foregroundColor: darkBrown,

                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          onPressed: () {
                            ref
                                .read(customerProvider.notifier)
                                .updateMemo(
                                  currentCustomer.id,
                                  memoController.text,
                                );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("カルテを保存しました")),
                            );
                          },

                          child: const Text(
                            "カルテを保存",

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔥売上履歴
                const Text(
                  "売上履歴",

                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),

                const SizedBox(height: 14),

                salesDocs.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("履歴がありません"),
                        ),
                      )
                    : Column(
                        children: salesDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),

                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFEFD),

                              borderRadius: BorderRadius.circular(18),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),

                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),

                              title: Text(
                                "¥${data['price']}",

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,

                                  fontSize: 18,
                                ),
                              ),

                              subtitle: Text(
                                "${data['menu']} / ${data['date'].toDate().month}/${data['date'].toDate().day}",
                              ),

                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),

                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('sales')
                                      .doc(doc.id)
                                      .delete();
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
