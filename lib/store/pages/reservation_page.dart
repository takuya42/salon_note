import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../role_select/role_select_page.dart';
import '../tabs/reservation_tab.dart';
import '../tabs/sales_tab.dart';
import '../tabs/customer_tab.dart';
import '../../mypage/pages/mypage_page.dart';

class ReservationPage extends StatelessWidget {
  const ReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: _ReservationPageBody(),
    );
  }
}

class _ReservationPageBody extends StatelessWidget {
  const _ReservationPageBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const RoleSelectPage(),
              ),
                  (route) => false,
            );
          },
        ),

        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Text("...");
            }

            final userData =
            userSnapshot.data!.data() as Map<String, dynamic>?;

            final shopId = userData?['shopId'];

            if (shopId == null) {
              return const Text("店舗なし");
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('shops')
                  .doc(shopId)
                  .get(),
              builder: (context, shopSnapshot) {
                if (!shopSnapshot.hasData) {
                  return const Text("...");
                }

                final shopData =
                shopSnapshot.data!.data() as Map<String, dynamic>?;

                final name = shopData?['name'] ?? "店舗名";

                return Text(name);
              },
            );
          },
        ),

        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyPage(isOwner: true),
                ),
              );
            },
          ),
        ],

        bottom: const TabBar(
          labelColor: Color(0xFFB08E85),
          unselectedLabelColor: Colors.black54,
          indicatorColor: Color(0xFFB08E85),
          tabs: [
            Tab(text: "予約"),
            Tab(text: "売上"),
            Tab(text: "顧客"),
          ],
        ),
      ),

      body: const TabBarView(
        children: [
          ReservationTab(),
          SalesTab(),
          CustomerTab(),
        ],
      ),
    );
  }
}