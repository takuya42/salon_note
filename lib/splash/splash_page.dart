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
    final needsUpdate = await _forceUpdateService.shouldForceUpdate();

    if (!mounted) {
      return;
    }

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
            backgroundColor: const Color(0xFFF2E6E2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'アップデートのお知らせ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3C38),
              ),
            ),
            content: const Text(
              'このバージョンはご利用いただけません。\n最新バージョンへアップデートしてください。',
              style: TextStyle(
                color: Color(0xFF4A3C38),
                height: 1.5,
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD8C2B9),
                    foregroundColor: const Color(0xFF4A3C38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _forceUpdateService.openStore();
                  },
                  child: const Text(
                    'アップデート',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
