import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/pages/auth_gate.dart';
import '../../auth/services/auth_service.dart';
import '../providers/onboarding_provider.dart';

const _ink = Color(0xFF292421);
const _muted = Color(0xFF817672);
const _accent = Color(0xFFAD877C);
const _surface = Color(0xFFFAF8F6);

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _page = 0;
  bool _isSigningIn = false;

  Future<void> _next() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openLogin() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const AuthGate()),
    );
  }

  Future<void> _signIn(Future<Object?> Function() action) async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final result = await action();
      if (result == null) {
        if (mounted) setState(() => _isSigningIn = false);
        return;
      }
      await ref.read(onboardingCompletedProvider.notifier).complete();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute<void>(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSigningIn = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
              child: Row(
                children: [
                  const Text(
                    'SalonNote',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  if (_page < 4)
                    TextButton(
                      onPressed: () => _pageController.animateToPage(
                        4,
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text(
                        'スキップ',
                        style: TextStyle(color: _muted),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _FeaturePage(
                    eyebrow: '01  RESERVATIONS',
                    title: '予約管理',
                    subtitle: '予約をかんたんに管理',
                    hint: 'カレンダーを左右にスワイプ',
                    demo: const _CalendarDemo(),
                    onNext: _next,
                  ),
                  _FeaturePage(
                    eyebrow: '02  CUSTOMERS',
                    title: '顧客管理',
                    subtitle: '顧客情報をまとめて管理',
                    hint: '予約カードをタップ',
                    demo: const _CustomerDemo(),
                    onNext: _next,
                  ),
                  _FeaturePage(
                    eyebrow: '03  SALES',
                    title: '売上管理',
                    subtitle: '売上を自動で集計',
                    hint: '今月の変化をプレビュー',
                    demo: const _SalesDemo(),
                    onNext: _next,
                  ),
                  _FeaturePage(
                    eyebrow: '04  WEB BOOKING',
                    title: 'Web予約',
                    subtitle: '24時間いつでも予約受付',
                    hint: '空いている時間をタップ',
                    demo: const _WebBookingDemo(),
                    onNext: _next,
                  ),
                  _StartPage(
                    isLoading: _isSigningIn,
                    onApple: () => _signIn(_authService.signInWithApple),
                    onGoogle: () => _signIn(_authService.signInWithGoogle),
                    onEmail: _openLogin,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    width: index == _page ? 24 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? _accent
                          : const Color(0xFFDCD5D1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.demo,
    required this.onNext,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String hint;
  final Widget demo;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
          child: Column(
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: _muted, fontSize: 16),
              ),
              const SizedBox(height: 28),
              demo,
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.hand_draw,
                    size: 17,
                    color: _muted,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    hint,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '次へ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 292,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0EBE8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2F2420),
            blurRadius: 35,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CalendarDemo extends StatefulWidget {
  const _CalendarDemo();

  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  final PageController _controller = PageController(viewportFraction: 0.91);
  int _month = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const months = ['6月', '7月', '8月'];
    return _DemoCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '2026年 ${months[_month]}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(CupertinoIcons.calendar, color: _accent, size: 21),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _month = value),
              itemCount: months.length,
              itemBuilder: (_, page) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemCount: 28,
                  itemBuilder: (_, index) {
                    final selected = index == 10 + page * 2;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: selected ? _accent : const Color(0xFFFAF8F6),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: selected ? Colors.white : _muted,
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDemo extends StatefulWidget {
  const _CustomerDemo();

  @override
  State<_CustomerDemo> createState() => _CustomerDemoState();
}

class _CustomerDemoState extends State<_CustomerDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本日の予約',
            style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _expanded ? const Color(0xFFF3E9E5) : _surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFE1CBC3),
                        child: Text('M', style: TextStyle(color: _ink)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('松本 さくら 様', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('13:30  カット＋カラー', style: TextStyle(color: _muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down, color: _muted, size: 17),
                    ],
                  ),
                  AnimatedSize(
                    duration: Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: _expanded
                        ? const Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.heart_fill, color: _accent, size: 15),
                                SizedBox(width: 7),
                                Text('前回：透明感ベージュ / 6トーン', style: TextStyle(color: _muted, fontSize: 12)),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _MiniCustomerRow(initial: 'A', name: '青木 まり 様', detail: '16:00  トリートメント'),
        ],
      ),
    );
  }
}

class _MiniCustomerRow extends StatelessWidget {
  const _MiniCustomerRow({required this.initial, required this.name, required this.detail});
  final String initial;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEDE8E5),
            child: Text(initial, style: const TextStyle(color: _muted)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesDemo extends StatefulWidget {
  const _SalesDemo();

  @override
  State<_SalesDemo> createState() => _SalesDemoState();
}

class _SalesDemoState extends State<_SalesDemo> {
  bool _animated = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _animated = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    const values = [4.0, 7.0, 5.5, 10.0, 8.0, 12.0, 14.0];
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今月の売上', style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 5),
          const Text('¥486,200', style: TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('↗  先月比 12.8%', style: TextStyle(color: Color(0xFF668673), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 16,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  values.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _animated ? values[index] : 0.15,
                        width: 16,
                        color: index == values.length - 1 ? _accent : const Color(0xFFDCCBC5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 900),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebBookingDemo extends StatefulWidget {
  const _WebBookingDemo();

  @override
  State<_WebBookingDemo> createState() => _WebBookingDemoState();
}

class _WebBookingDemoState extends State<_WebBookingDemo> {
  static const _times = ['10:00', '11:30', '14:00', '16:30'];
  String? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFF0E4E0),
                child: Icon(CupertinoIcons.globe, color: _accent, size: 20),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Web予約ページ',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'カット  ¥5,500 / 60分',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '6月12日（金）の空き時間',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _times.map((time) {
              final selected = time == _selectedTime;
              return ChoiceChip(
                label: Text(time),
                selected: selected,
                showCheckmark: false,
                selectedColor: _accent,
                backgroundColor: _surface,
                side: BorderSide(
                  color: selected ? _accent : const Color(0xFFE8E0DC),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _selectedTime = time),
              );
            }).toList(),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedTime == null
                  ? const Color(0xFFF4F0EE)
                  : const Color(0xFFE8F0EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedTime == null
                      ? CupertinoIcons.hand_draw
                      : CupertinoIcons.check_mark_circled_solid,
                  color: _selectedTime == null
                      ? _muted
                      : const Color(0xFF668673),
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? 'ご希望の時間を選択してください'
                        : '6月12日 $_selectedTime を選択中',
                    style: TextStyle(
                      color: _selectedTime == null
                          ? _muted
                          : const Color(0xFF4F705D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPage extends StatelessWidget {
  const _StartPage({
    required this.isLoading,
    required this.onApple,
    required this.onGoogle,
    required this.onEmail,
  });

  final bool isLoading;
  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 12))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 28),
          const Text('今すぐ始める', style: TextStyle(color: _ink, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1)),
          const SizedBox(height: 10),
          const Text('サロンワークを、もっと美しくシンプルに。', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontSize: 15)),
          const SizedBox(height: 38),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 55),
              child: CupertinoActivityIndicator(radius: 14),
            )
          else ...[
            _SocialButton(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.apple, size: 25),
              label: 'Appleでログイン',
              onPressed: onApple,
            ),
            const SizedBox(height: 12),
            _SocialButton(
              backgroundColor: Colors.white,
              foregroundColor: _ink,
              icon: Image.asset('assets/images/google.png', width: 20, height: 20),
              label: 'Googleでログイン',
              onPressed: onGoogle,
              border: const BorderSide(color: Color(0xFFE2DCDA)),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onEmail,
              child: const Text('メールアドレスでログイン', style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            '続行すると、利用規約とプライバシーポリシーに\n同意したものとみなされます。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA39A96), fontSize: 11, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.border,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
