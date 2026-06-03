import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:salon_note/auth/pages/login_page.dart';
import 'package:salon_note/services/force_update_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final ForceUpdateService _forceUpdateService = ForceUpdateService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    /// Webは強制アップデートをスキップ
    if (kIsWeb) {
      _goToLogin();
      return;
    }

    final needsUpdate = await _forceUpdateService.shouldForceUpdate();

    if (!mounted) return;

    if (needsUpdate) {
      _showForceUpdateDialog();
      return;
    }

    _goToLogin();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Future<void> _showForceUpdateDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('アップデートのお知らせ'),
            content: const Text(
              'このバージョンはご利用いただけません。\n最新バージョンへアップデートしてください。',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  _forceUpdateService.openStore();
                },
                child: const Text('アップデート'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFD8C2B9),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SalonNote',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3C38),
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Color(0xFF4A3C38),
            ),
          ],
        ),
      ),
    );
  }
}