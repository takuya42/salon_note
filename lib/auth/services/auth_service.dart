import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _createUserDocIfNeeded(User user) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'plan': 'free',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _createUserDocIfNeeded(result.user!);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User?> signInWithApple() async {
    try {
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

      final result = await _auth.signInWithCredential(oauthCredential);
      final user = result.user;

      if (user != null && appleCredential.givenName != null) {
        final displayName =
        '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
            .trim();
        await user.updateDisplayName(displayName);
      }

      if (user != null) {
        await _createUserDocIfNeeded(user);
      }

      return user;
    } catch (e) {
      debugPrint('Apple signIn error: $e');
      throw 'Appleログインに失敗しました';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _createUserDocIfNeeded(user);
      }

      return userCredential;
    } catch (e) {
      debugPrint("Googleログインエラー: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'メールアドレスの形式が違います';
      case 'user-not-found':
        return 'ユーザーが存在しません';
      case 'wrong-password':
      case 'invalid-credential':
        return 'メールアドレスまたはパスワードが違います';
      case 'email-already-in-use':
        return 'このメールは既に登録されています';
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上）';
      case 'too-many-requests':
        return 'しばらく時間をおいて再試行してください';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      default:
        return 'エラーが発生しました (${e.code})';
    }
  }
}