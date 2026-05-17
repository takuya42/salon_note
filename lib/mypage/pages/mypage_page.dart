import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ payment/pages/subscription_page.dart';
import '../../auth/pages/login_page.dart';

import '../../providers/user_provider.dart';
import '../../settings/pages/settings_page.dart';

class MyPage extends ConsumerWidget {
  final bool isOwner;

  const MyPage({
    super.key,
    required this.isOwner,
  });


  /// 🔥 連携 / 解除
  void _handleAuthAction(
      BuildContext context,
      User? user,
      String providerId,
      bool isLinked,
      ) {
    if (isLinked) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("連携解除"),
          content: const Text("このログインを解除しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _unlink(providerId);
              },
              child: const Text("解除"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("連携"),
          content: const Text("このログインを連携しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _link(context, providerId);
              },
              child: const Text("連携する"),
            ),
          ],
        ),
      );
    }
  }

  /// 🔥 解除
  Future<void> _unlink(String providerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.unlink(providerId);
  }

  /// 🔥 連携
  Future<void> _link(BuildContext context, String providerId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {

      /// 🔵 Google
      if (providerId == 'google.com') {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.linkWithCredential(credential);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google連携完了")),
        );
      }

      /// 🍎 Apple
      if (providerId == 'apple.com') {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        await user.linkWithCredential(oauthCredential);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apple連携完了")),
        );
      }

      /// 📧 メール
      if (providerId == 'password') {
        final passController = TextEditingController();
        final confirmController = TextEditingController();

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("パスワード設定"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "パスワード"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "確認用"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("キャンセル"),
              ),
              TextButton(
                onPressed: () async {
                  final password = passController.text;
                  final confirm = confirmController.text;

                  if (password.isEmpty || confirm.isEmpty) return;
                  if (password.length < 6) return;
                  if (password != confirm) return;

                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );

                  await user.linkWithCredential(credential);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("メール連携完了")),
                  );
                },
                child: const Text("設定"),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("エラー: $e")),
      );
    }
  }

  /// 🔥 メール変更（完全版）
  Future<void> _editEmail(BuildContext context, User? user) async {
    if (user == null) return;

    final emailController = TextEditingController();
    final passController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("メール変更"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "新しいメール"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "パスワード"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text;
              final password = passController.text;

              if (email.isEmpty || password.isEmpty) return;

              try {
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password,
                );

                await user.reauthenticateWithCredential(credential);

                /// 🔥 ここが重要
                await user.verifyBeforeUpdateEmail(email);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("確認メールを送信しました")),
                );

                /// 🔥 password連携チェック
                final providers =
                user.providerData.map((e) => e.providerId).toList();

                if (!providers.contains('password')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("メールログイン未連携です")),
                  );
                }

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("エラー: $e")),
                );
              }
            },
            child: const Text("変更"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final passController = TextEditingController();
    final confirmController = TextEditingController();

    bool obscure = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("パスワード変更"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// 新パスワード
                  TextField(
                    controller: passController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "新しいパスワード",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 確認
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: "確認用",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("キャンセル"),
                ),
                TextButton(
                  onPressed: () async {
                    final password = passController.text;
                    final confirm = confirmController.text;

                    if (password.isEmpty || confirm.isEmpty) return;
                    if (password.length < 6) return;
                    if (password != confirm) return;

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      await user?.updatePassword(password);

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("パスワード変更完了")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("エラー: $e")),
                      );
                    }
                  },
                  child: const Text("変更"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final providers =
    user.providerData.map((e) => e.providerId).toList();

    if (!providers.contains('password')) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("退会するにはメールログイン連携が必要です"),
        ),
      );

      return;
    }


    final passController = TextEditingController();

    /// 🔴 確認ダイアログ
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("退会確認"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Text("本当に退会しますか？"),

            const SizedBox(height: 10),

            /// 🔥 パスワード入力
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "パスワード",
              ),
            ),
          ],
        ),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),

          TextButton(
            onPressed: () async {

              final password = passController.text;

              if (password.isEmpty) return;

              try {
                /// 🔥 再認証
                final credential = EmailAuthProvider.credential(
                  email: user.email!,
                  password: password,
                );

                await user.reauthenticateWithCredential(credential);

                /// 🔥 Firestore削除（必要なら）
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .delete();

                /// 🔥 アカウント削除

                await user.delete();

                await FirebaseAuth.instance.signOut();

                Navigator.pop(context);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                      (route) => false,
                );

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("エラー: $e")),
                );
              }
            },
            child: const Text("退会する"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFD8C2B9),

      appBar: AppBar(
        title: const Text("設定"),
        backgroundColor: Color(0xFFD8C2B9),
        foregroundColor: Colors.black,

        actions: [

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

              final plan = data?['plan'] ?? 'free';

              if (plan != 'pro') {
                return const SizedBox();
              }

              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB88484),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [

                    Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 16,
                    ),

                    SizedBox(width: 4),

                    Text(
                      "PRO",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _card(
              child: Column(
                children: [

                  /// 🔥 メール編集
                  _item(
                    icon: Icons.email,
                    title: "メール",
                    value: user?.email ?? "",
                    onTap: () => _editEmail(context, user),
                  ),

                  _divider(),

                  _item(
                    icon: Icons.lock,
                    title: "パスワード",
                    value: "••••••••",
                    onTap: () {
                        _changePassword(context);
                    },
                  ),
                  _divider(),

                  _loginItem(context, user, "Googleログイン", "google.com"),
                  _divider(),
                  _loginItem(context, user, "Appleログイン", "apple.com"),
                  _divider(),
                  _loginItem(context, user, "メールログイン", "password"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (isOwner)
              _card(
                child: _item(
                  icon: Icons.workspace_premium,
                  title: "Proプラン",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPage(),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            if (isOwner)
            _card(
              child: _item(
                icon: Icons.settings,
                title: "サロン設定",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            _card(
              child: _item(
                icon: Icons.mail,
                title: "お問い合わせ",
                onTap: () {
                  _openUrl("https://forms.gle/2fm7RfxiPTeNhhQZA");
                },
              ),
            ),

            const SizedBox(height: 20),


            _card(
              child: Column(
                children: [

                  _item(
                    icon: Icons.description,
                    title: "利用規約",
                    onTap: () {
                      _openUrl("https://www.notion.so/flutter-family/Salon-Note-354b5c1f2cef80a69e11e092cddc522b?source=copy_link");
                    },
                  ),

                  _divider(),

                  _item(
                    icon: Icons.privacy_tip,
                    title: "プライバシーポリシー",
                    onTap: () {
                      _openUrl("https://www.notion.so/flutter-family/Salon-Note-354b5c1f2cef80ccb6a5d44980572294?source=copy_link");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _card(
              child: _item(
                icon: Icons.logout,
                title: "ログアウト",
                color: Colors.red,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),

            ),
            const SizedBox(height: 20),

            _card(
              child: _item(
                icon: Icons.delete,
                title: "退会",
                color: Colors.red,
                onTap: () {
                  _deleteAccount(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// UI
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF2E9E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    String? value,
    VoidCallback? onTap,
    Color color = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            if (value != null) Text(value),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider();

  Widget _loginItem(
      BuildContext context,
      User? user,
      String title,
      String providerId,
      ) {
    final providers =
        user?.providerData.map((e) => e.providerId).toList() ?? [];

    final isLinked = providers.contains(providerId);

    return InkWell(
      onTap: () {
        _handleAuthAction(context, user, providerId, isLinked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildIcon(providerId),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            Text(
              isLinked ? "連携済み" : "未連携",
              style: TextStyle(
                color: isLinked ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String providerId) {
    switch (providerId) {
      case 'google.com':
        return Image.asset('assets/images/google.png', width: 24);
      case 'apple.com':
        return const Icon(Icons.apple);
      case 'password':
        return const Icon(Icons.email);
      default:
        return const Icon(Icons.link);
    }
  }
  /// 🔥 ここに追加（classの中・buildの外）
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}