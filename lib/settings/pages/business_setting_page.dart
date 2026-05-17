import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessSettingPage extends StatefulWidget {
  const BusinessSettingPage({super.key});

  @override
  State<BusinessSettingPage> createState() => _BusinessSettingPageState();
}

class _BusinessSettingPageState extends State<BusinessSettingPage> {

  /// 営業時間
  TimeOfDay openTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay closeTime = const TimeOfDay(hour: 20, minute: 0);

  /// 定休日
  final List<String> weekDays = ["月", "火", "水", "木", "金", "土", "日"];
  List<bool> isClosed = List.generate(7, (_) => false);

  bool isLoading = true;

  String? shopId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// 🔥 初期化（shopId → 設定読み込み）
  Future<void> _init() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    shopId = userDoc.data()?['shopId'];

    await _loadSettings();
  }

  /// 🔥 設定取得（shopsから）
  Future<void> _loadSettings() async {

    if (shopId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      openTime = TimeOfDay(
        hour: data["openHour"] ?? 10,
        minute: data["openMinute"] ?? 0,
      );

      closeTime = TimeOfDay(
        hour: data["closeHour"] ?? 20,
        minute: data["closeMinute"] ?? 0,
      );

      List closedDays = data["closedDays"] ?? [];

      for (int i = 0; i < 7; i++) {
        isClosed[i] = closedDays.contains(i + 1);
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  /// 🔥 保存（shopsに保存）
  Future<void> _save() async {

    if (shopId == null) return;

    List<int> closedDays = [];
    for (int i = 0; i < isClosed.length; i++) {
      if (isClosed[i]) {
        closedDays.add(i + 1);
      }
    }

    await FirebaseFirestore.instance
        .collection('shops')
        .doc(shopId)
        .collection('settings')
        .doc('business')
        .set({
      "openHour": openTime.hour,
      "openMinute": openTime.minute,
      "closeHour": closeTime.hour,
      "closeMinute": closeTime.minute,
      "closedDays": closedDays,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("保存しました")),
    );
  }

  /// 時間選択
  Future<void> _selectTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? openTime : closeTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpen) {
          openTime = picked;
        } else {
          closeTime = picked;
        }
      });
    }
  }

  String _format(TimeOfDay time) => time.format(context);

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("営業設定"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 営業時間
            _card(
              child: Column(
                children: [
                  _timeTile(
                    title: "開店時間",
                    time: _format(openTime),
                    onTap: () => _selectTime(true),
                  ),
                  const Divider(),
                  _timeTile(
                    title: "閉店時間",
                    time: _format(closeTime),
                    onTap: () => _selectTime(false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 定休日
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "定休日",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: List.generate(weekDays.length, (index) {
                      return FilterChip(
                        label: Text(weekDays[index]),
                        selected: isClosed[index],
                        onSelected: (value) {
                          setState(() {
                            isClosed[index] = value;
                          });
                        },
                        selectedColor: Colors.orange.withOpacity(0.3),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// 保存
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("保存"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// カード
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }

  /// 時間タイル
  Widget _timeTile({
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}