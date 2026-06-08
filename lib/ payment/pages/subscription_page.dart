import 'package:flutter/material.dart';
import '../../services/purchase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final PurchaseService _purchaseService = PurchaseService();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _purchaseService.init();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    setState(() => isLoading = true);

    try {
      await _purchaseService.buySubscription();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("購入画面を表示中...")));
    } catch (e) {

      if (e.toString().contains("userCancelled")) {
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text("購入エラーが発生しました")),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _restore() async {
    try {
      await _purchaseService.restore();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("購入を復元しました")));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("復元エラー: $e")));
    }
  }

  void _showPolicyDialog(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: const Text(
            "正式な内容はリリース前にURLで設定します。\n\n"
            "サブスクリプションはApp Storeの規約に従って管理されます。",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _feature(
    String title, {
    String? description,
    String? emoji,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: emoji == null
                ? const Icon(Icons.check, color: Color(0xFFB08E85))
                : Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final plan = data?['plan'] ?? 'free';
        final isPro = plan == 'pro';

        return Scaffold(
          backgroundColor: const Color(0xFFD8C2B9),

          appBar: AppBar(
            title: const Text("Proプラン"),
            backgroundColor: const Color(0xFFD8C2B9),
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: _restore,
                child: const Text("復元", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),

          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E6E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Proプランでできること",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Web予約機能を利用するにはProプランへの登録が必要です",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB88484),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Web予約機能はPro限定",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _feature("広告なし"),
                    _feature("予約件数 無制限"),
                    _feature("顧客管理 無制限"),
                    _feature("売上分析"),
                    _feature(
                      "Web予約機能",
                      emoji: "🌐",
                      description: "お客様が24時間いつでもWebから予約可能",
                    ),
                    _feature(
                      "Instagramリンク掲載",
                      emoji: "📱",
                      description: "店舗ページからInstagramへ誘導可能",
                    ),
                    _feature(
                      "LINEリンク掲載",
                      emoji: "💬",
                      description: "店舗ページからLINEへ誘導可能",
                    ),
                    _feature(
                      "店舗ページ公開",
                      emoji: "🏪",
                      description: "SalonNote上で店舗紹介ページを公開可能",
                    ),

                    if (isPro) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB88484),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            "Proプラン利用中",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "1ヶ月自動更新 ¥2,980 / 月",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "いつでもキャンセル可能",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isPro || isLoading ? null : _buy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB88484),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isPro ? "Proプラン利用中" : "今すぐアップグレード",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        "購入後はApp Storeの設定から解約できます",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            _openUrl(
                              "https://www.notion.so/flutter-family/Salon-Note-359b5c1f2cef80d2aab6c3c929c6b722?source=copy_link",
                            );
                          },
                          child: const Text("利用規約"),
                        ),

                        const Text(" / "),

                        TextButton(
                          onPressed: () {
                            _openUrl(
                              "https://www.notion.so/flutter-family/Salon-Note-361b5c1f2cef801593c9cb2c1150fa60?source=copy_link",
                            );
                          },
                          child: const Text("プライバシーポリシー"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
