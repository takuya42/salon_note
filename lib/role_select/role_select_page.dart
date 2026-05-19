import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/banner_ad_widget.dart';

import '../store/pages/reservation_page.dart';
import '../customer/customer_booking_page.dart';
import '../auth/pages/login_page.dart';
import '../auth/pages/shop_create_page.dart';
import '../ payment/pages/subscription_page.dart';

const bool isDev = true;

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  /// 🔥 店舗用押したときの処理
  Future<void> handleStore(BuildContext context) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    final shopId = data?['shopId'];

    if (shopId == null) {
      /// 🔥 店舗未登録 → 登録画面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ShopCreatePage(),
        ),
      );
    } else {
      /// 🔥 登録済み → 予約画面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ReservationPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFFD8C2B9),

      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              iconSize: 36,
              icon: const Icon(Icons.workspace_premium),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPage(),
                  ),
                );
              },
            ),
          ),
        ],
        title: const Text("SalonNote"),
        backgroundColor: Color(0xFFD8C2B9),
        elevation: 0,
        foregroundColor: Colors.black,


      ),

      body: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Color(0xFFF2E6E2),
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "どちらで利用しますか？",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// 🔥 店舗用
            _buildCard(
              icon: Icons.store,
              title: "店舗用",
              subtitle: "予約・売上・顧客管理",
              onTap: () => handleStore(context),
            ),
            const SizedBox(height: 10),

            /// 🔥 店舗ID作成ボタン
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final data =
                snapshot.data!.data() as Map<String, dynamic>?;

                final shopId = data?['shopId'];

                /// 🔥 店舗ID作成済みなら非表示
                if (shopId != null &&
                    shopId.toString().isNotEmpty) {
                  return const SizedBox();
                }

                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("店舗IDを作成する"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShopCreatePage(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            /// 🔥 お客様用
            _buildCard(
              icon: Icons.person,
              title: "お客様用",
              subtitle: "予約・空き状況確認",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerBookingPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),

            const Text(
              "無料プランをご利用中",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  /// UIカード
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          children: [

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Color(0xFF2C2C2C)),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}