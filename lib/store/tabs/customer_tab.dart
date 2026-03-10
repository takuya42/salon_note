import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/banner_ad_widget.dart';

import '../providers/customer_provider.dart';
import '../models/customer_model.dart';
import '../pages/customer_detail_page.dart';

const primaryColor = Color(0xFFD9B8A5);
const darkBrown = Color(0xFF5B463C);
const backgroundColor = Color(0xFFFCFCFC);

class CustomerTab extends ConsumerStatefulWidget {
  const CustomerTab({super.key});

  @override
  ConsumerState<CustomerTab> createState() => _CustomerTabState();
}

class _CustomerTabState extends ConsumerState<CustomerTab> {
  String searchText = "";

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  /// 顧客追加
  void addCustomer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final plan = userDoc.data()?['plan'] ?? 'free';

    final customerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('customers')
        .get();

    final customerCount = customerSnapshot.docs.length;

    if (plan == 'free' && customerCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("無料プランは顧客3人までです"),
        ),
      );
      return;
    }

    TextEditingController nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.all(20),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 上バー
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                /// タイトル
                const Text(
                  "顧客追加",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),

                const SizedBox(height: 24),

                /// 入力
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "名前",
                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: primaryColor.withOpacity(0.25),
                      ),
                    ),

                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(16),
                      ),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 保存
                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBrown,
                      foregroundColor: Colors.white,
                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    onPressed: () async {
                      if (nameController.text.isEmpty) return;

                      await ref
                          .read(customerProvider.notifier)
                          .addCustomer(nameController.text);

                      Navigator.pop(context);
                    },

                    child: const Text(
                      "保存",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);

    final filtered = customers.where((c) {
      return c.name
          .toLowerCase()
          .contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),

        child: FloatingActionButton(
          backgroundColor: darkBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          onPressed: addCustomer,

          child: const Icon(Icons.add),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            /// 検索
            TextField(
              decoration: InputDecoration(
                hintText: "顧客検索",

                hintStyle: TextStyle(
                  color: darkBrown.withOpacity(0.5),
                ),

                prefixIcon: Icon(
                  Icons.search,
                  color: darkBrown.withOpacity(0.7),
                ),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: primaryColor.withOpacity(0.25),
                  ),
                ),

                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(18),
                  ),
                  borderSide: BorderSide(
                    color: primaryColor,
                    width: 1.5,
                  ),
                ),
              ),

              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),

            const SizedBox(height: 20),

            /// 一覧
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Text(
                  "顧客がいません",
                  style: TextStyle(
                    color: darkBrown.withOpacity(0.6),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: filtered.length,

                itemBuilder: (context, index) {
                  Customer customer = filtered[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),

                      border: Border.all(
                        color:
                        primaryColor.withOpacity(0.15),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),

                      leading: Container(
                        width: 48,
                        height: 48,

                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(
                            0.15,
                          ),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.person,
                          color: darkBrown,
                        ),
                      ),

                      title: Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkBrown,
                        ),
                      ),

                      subtitle: uid == null
                          ? Text(
                        "来店回数: 0回",
                        style: TextStyle(
                          color: darkBrown
                              .withOpacity(0.6),
                        ),
                      )
                          : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(uid)
                            .collection('sales')
                            .where(
                          'customerId',
                          isEqualTo: customer.id,
                        )
                            .snapshots(),

                        builder:
                            (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              "来店回数: 0回",
                              style: TextStyle(
                                color: darkBrown
                                    .withOpacity(
                                    0.6),
                              ),
                            );
                          }

                          final count = snapshot
                              .data!.docs.length;

                          return Text(
                            "来店回数: ${count}回",
                            style: TextStyle(
                              color: darkBrown
                                  .withOpacity(0.6),
                            ),
                          );
                        },
                      ),

                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),

                        onPressed: () async {
                          await ref
                              .read(
                            customerProvider
                                .notifier,
                          )
                              .deleteCustomer(
                            customer.id,
                          );
                        },
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailPage(
                                  customer: customer,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            /// 広告
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final data = snapshot.data!.data()
                as Map<String, dynamic>?;

                final plan = data?['plan'] ?? 'free';

                if (plan == 'pro') {
                  return const SizedBox();
                }

                return Column(
                  children: [

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color:
                        primaryColor.withOpacity(0.15),

                        borderRadius:
                        BorderRadius.circular(30),
                      ),

                      child: Text(
                        "無料プランをご利用中",
                        style: TextStyle(
                          color:
                          darkBrown.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Center(
                      child: BannerAdWidget(),
                    ),

                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}