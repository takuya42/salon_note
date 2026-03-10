import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import '../../role_select/role_select_page.dart';

/// 🔥 本番用：ログインスキップOFF
const bool isDev = false;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    /// 🔥 開発中だけログインスキップ
    if (isDev) {
      return const RoleSelectPage();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        /// 🔥 ローディング
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        /// 🔥 エラー
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text("エラーが発生しました"),
            ),
          );
        }

        /// 🔥 ログイン済み
        if (snapshot.hasData) {
          return const RoleSelectPage();
        }

        /// 🔥 未ログイン
        return const LoginPage();
      },
    );
  }
}