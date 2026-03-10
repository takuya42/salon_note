import 'package:flutter/material.dart';
import 'package:salon_note/auth/services/auth_service.dart';
import 'package:salon_note/auth/pages/register_page.dart';
import 'package:salon_note/role_select/role_select_page.dart';

const bool isDev = false;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final auth = AuthService();

  bool isLoading = false;

  Future<void> login() async {
    if (mounted) {
      setState(() => isLoading = false);
    }

    try {

      final user = await auth.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSelectPage(),
          ),
              (route) => false,
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ログイン失敗: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("メールアドレスを入力してください")),
      );
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("パスワード再設定メールを送信しました")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("送信失敗: $e")),
      );
    }
  }

  Future<void> appleLogin() async {
    try {

      final user = await auth.signInWithApple();

      if (user != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSelectPage(),
          ),
              (route) => false,
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Appleログイン失敗: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD8C2B9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFD8C2B9),
        elevation: 0,
        actions: [
          if (isDev)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectPage(),
                  ),
                );
              },
            ),
        ],
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF2E6E2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "SalonNote",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "メール",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "パスワード",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {

                        final resetController = TextEditingController();

                        showDialog(
                          context: context,
                          builder: (context) {

                            return AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),

                              title: const Text(
                                "パスワードをお忘れですか？",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),

                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  const Text(
                                    "パスワード再設定用のリンクをお送りします。\nメールアドレスを入力してください。",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  TextField(
                                    controller: resetController,
                                    style: const TextStyle(color: Colors.white),

                                    decoration: InputDecoration(
                                      labelText: "メールアドレス",
                                      labelStyle: const TextStyle(
                                        color: Colors.white54,
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),

                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD88C8C),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              actions: [

                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },

                                  child: const Text(
                                    "キャンセル",
                                    style: TextStyle(
                                      color: Color(0xFFD88C8C),
                                    ),
                                  ),
                                ),

                                ElevatedButton(
                                  onPressed: () async {

                                    final email =
                                    resetController.text.trim();

                                    if (email.isEmpty) return;

                                    try {

                                      await auth
                                          .sendPasswordResetEmail(email);

                                      if (context.mounted) {

                                        Navigator.pop(context);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "リセットメールを送信しました",
                                            ),
                                          ),
                                        );
                                      }

                                    } catch (e) {

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text("送信失敗: $e"),
                                        ),
                                      );
                                    }
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFFD88C8C),

                                    foregroundColor: Colors.black,

                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),

                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(18),
                                    ),
                                  ),

                                  child: const Text(
                                    "リセットメールを送信",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      child: const Text(
                        "パスワードをお忘れですか？",
                        style: TextStyle(
                          color: Color(0xFF8E7A74),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA67C73),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "ログイン",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      "新規登録",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: appleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apple, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Appleでログイン",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () async {
                      final result = await auth.signInWithGoogle();

                      if (result != null && context.mounted) {

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectPage(),
                          ),
                              (route) => false,
                        );

                      } else {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Googleログイン失敗")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/google.png",
                          height: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Googleでログイン",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}