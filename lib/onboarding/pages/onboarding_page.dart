import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/pages/auth_gate.dart';
import '../providers/onboarding_provider.dart';

const _ink = Color(0xFF6E5246);
const _muted = Color(0xFF9A8A84);
const _accent = Color(0xFFB88D7D);
const _surface = Color(0xFFFFFFFF);

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _page = 0;

  Future<void> _next() async {
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openAuthGate() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const AuthGate()),
    );
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
                    hint: '予約状況をひと目で確認',
                    demo: const _CalendarDemo(),
                    onNext: _next,
                  ),
                  _FeaturePage(
                    eyebrow: '02  CUSTOMERS',
                    title: '顧客管理',
                    subtitle: '顧客情報をまとめて管理',
                    hint: '顧客情報をひと目で確認',
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
                  _StartPage(onStart: _openAuthGate),
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
                      color: index == _page ? _accent : const Color(0xFFDCD5D1),
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
                  const Icon(CupertinoIcons.hand_draw, size: 17, color: _muted),
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

class _CalendarDemo extends StatelessWidget {
  const _CalendarDemo();

  static const _orange = Color(0xFFE3A16F);
  static const _line = Color(0xFFEDE5E0);

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        children: [
          const Row(
            children: [
              Text(
                '2026 6月',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Spacer(),
              Icon(CupertinoIcons.calendar, color: _accent, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              SizedBox(width: 38),
              _DemoDay(label: '日', date: '7'),
              _DemoDay(label: '月', date: '8'),
              _DemoDay(label: '火', date: '9', selected: true),
              _DemoDay(label: '水', date: '10'),
              _DemoDay(label: '木', date: '11'),
              _DemoDay(label: '金', date: '12'),
              _DemoDay(label: '土', date: '13', weekend: true),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: const [
                    _TimeLine(time: '10:00'),
                    _TimeLine(time: '11:00'),
                    _TimeLine(time: '12:00'),
                    _TimeLine(time: '13:00'),
                    _TimeLine(time: '14:00'),
                  ],
                ),
                Positioned(
                  top: 2,
                  bottom: 1,
                  left: 38,
                  right: 0,
                  child: Row(
                    children: List.generate(
                      7,
                      (index) => Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: index == 4
                                ? const Color(0xFFF4F0ED)
                                : Colors.transparent,
                            border: const Border(
                              left: BorderSide(color: _line, width: 0.7),
                            ),
                          ),
                          child: index == 4
                              ? const Center(
                                  child: Text(
                                    '定\n休\n日',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFB4AAA5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  // 11:00開始
                  left: 119,
                  // 火曜日列
                  width: 38,
                  height: 104,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFD18B58),
                          width: 0.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '山\n田\n様',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
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

class _DemoDay extends StatelessWidget {
  const _DemoDay({
    required this.label,
    required this.date,
    this.selected = false,
    this.weekend = false,
  });

  final String label;
  final String date;
  final bool selected;
  final bool weekend;

  @override
  Widget build(BuildContext context) {
    final color = weekend ? _accent : _muted;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 9)),
          const SizedBox(height: 3),
          Container(
            width: 25,
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _ink : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              date,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Transform.translate(
              offset: const Offset(0, -5),
              child: Text(
                time,
                style: const TextStyle(color: _muted, fontSize: 8),
              ),
            ),
          ),
          const Expanded(child: Divider(height: 1, color: _CalendarDemo._line)),
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

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.refresh, color: _ink),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '6月リピート率',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                      Text(
                        '68%',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('30日以内再来店', style: TextStyle(color: _muted, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.search, color: _muted),
                SizedBox(width: 10),
                Text('顧客検索', style: TextStyle(color: _muted)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFEDE8E5),
                  child: Icon(CupertinoIcons.person_fill, color: _ink),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '山田 太郎　様',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '来店回数: 3回',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
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

class _MiniCustomerRow extends StatelessWidget {
  const _MiniCustomerRow({
    required this.initial,
    required this.name,
    required this.detail,
  });

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
          const Text(
            '¥486,200',
            style: TextStyle(
              color: _ink,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

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
                        color: index == values.length - 1
                            ? _accent
                            : const Color(0xFFDCCBC5),
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

class _WebBookingDemo extends StatelessWidget {
  const _WebBookingDemo();

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SalonNote サロン',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),

          const SizedBox(height: 14),

          const _MiniField(
            icon: CupertinoIcons.person,
            label: 'お名前',
          ),

          const SizedBox(height: 8),

          const _MiniField(
            icon: CupertinoIcons.phone,
            label: '電話番号',
          ),

          const SizedBox(height: 8),

          const _MiniField(
            icon: CupertinoIcons.mail,
            label: 'メールアドレス',
          ),
          const SizedBox(height: 8),

          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.list_bullet,
                  size: 14,
                  color: _muted,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '人気メニュー ¥8,800',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 12,
                  color: _muted,
                ),
              ],
            ),
          ),

          const Spacer(),

          Container(
            height: 42,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '予約確定',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: _muted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
class _MiniChip extends StatelessWidget {
  const _MiniChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F1),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StartPage extends StatelessWidget {
  const _StartPage({required this.onStart});

  final VoidCallback onStart;

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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('assets/images/icon.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '今すぐ始める',
            style: TextStyle(
              color: _ink,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'サロンの毎日をもっとスマートに。',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 42),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'SalonNoteを始める',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ログイン済みの場合は、そのまま予約管理画面へ進みます。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFA39A96), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
