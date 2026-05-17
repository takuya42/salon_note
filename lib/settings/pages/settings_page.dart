import 'package:flutter/material.dart';
import 'package:salon_note/settings/pages/business_setting_page.dart';
import 'package:salon_note/settings/pages/menu_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


const primaryColor = Color(0xFFD8C2B9);
const darkBrown = Color(0xFF5C4A43);
const backgroundColor = Color(0xFFF7F3F0);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int interval = 30;

  @override
  void initState() {
    super.initState();
    _loadInterval();
  }

  Future<String?> _getShopId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return userDoc.data()?['shopId'];
  }

  Future<void> _loadInterval() async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .get();

    if (doc.exists) {
      setState(() {
        interval = doc.data()?['interval'] ?? 30;
      });
    }
  }

  Future<void> _saveInterval(int value) async {
    final shopId = await _getShopId();
    if (shopId == null) return;

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .set({
      'interval': value,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text("設定"),
        backgroundColor: primaryColor,
        foregroundColor: darkBrown,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("基本設定"),

          _settingCard(
            icon: Icons.access_time,
            title: "営業設定",
            subtitle: "営業時間・定休日を設定",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BusinessSettingPage(),
                ),
              ).then((_) {
                _loadInterval();
              });
            },
          ),

          _settingCard(
            icon: Icons.list_alt,
            title: "メニュー・料金",
            subtitle: "施術メニューを管理",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MenuPage(),
                ),
              );
            },
          ),

          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.timer,
                    color: darkBrown,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "時間単位設定",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "カレンダーの表示単位",
                        style: TextStyle(
                          color: darkBrown.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                DropdownButton<int>(
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  value: interval,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 15,
                      child: Text("15分"),
                    ),
                    DropdownMenuItem(
                      value: 30,
                      child: Text("30分"),
                    ),
                    DropdownMenuItem(
                      value: 60,
                      child: Text("60分"),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) return;

                    setState(() {
                      interval = value;
                    });

                    await _saveInterval(value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          color: darkBrown.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: darkBrown,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(
                      color: darkBrown.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: darkBrown,
            ),
          ],
        ),
      ),
    );
  }
}