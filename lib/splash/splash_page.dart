import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/pages/auth_gate.dart';
import '../onboarding/pages/onboarding_page.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../services/force_update_service.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _minimumDisplayDuration = Duration(milliseconds: 1800);

  final ForceUpdateService _forceUpdateService = ForceUpdateService();
  late final AnimationController _animationController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );
    _animationController.forward();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final minimumDelay = Future<void>.delayed(_minimumDisplayDuration);

    if (!kIsWeb) {
      final needsUpdate = await _forceUpdateService.shouldForceUpdate();
      if (!mounted) return;
      if (needsUpdate) {
        await minimumDelay;
        if (mounted) _showForceUpdateDialog();
        return;
      }
    }

    await minimumDelay;
    if (!mounted) return;

    final completed = ref.read(onboardingCompletedProvider);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => completed
            ? const AuthGate()
            : const OnboardingPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  Future<void> _showForceUpdateDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('アップデートのお知らせ'),
          content: const Text(
            'このバージョンはご利用いただけません。\n最新バージョンへアップデートしてください。',
          ),
          actions: [
            FilledButton(
              onPressed: _forceUpdateService.openStore,
              child: const Text('アップデート'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F6),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFCF9),
              Color(0xFFF7F0EB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 32,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/images/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _textOpacity,
                  child: const Column(
                    children: [
                      Text(
                        'SalonNote',
                        style: TextStyle(
                          color: Color(0xFF272321),
                          fontSize: 31,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '予約管理・顧客管理・売上管理',
                        style: TextStyle(
                          color: Color(0xFF8C817C),
                          fontSize: 14,
                          letterSpacing: 1.1,
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
