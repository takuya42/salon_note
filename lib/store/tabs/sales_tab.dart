import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/banner_ad_widget.dart';
import '../providers/sales_provider.dart';
import '../widgets/sales_editor_sheet.dart';

const _background = Color(0xFFFAF7F4);
const _surface = Color(0xFFFFFDFC);
const _beige = Color(0xFFD8C2B9);
const _roseBrown = Color(0xFFB08E85);
const _darkBrown = Color(0xFF5B463C);
const _mutedBrown = Color(0xFF8E766C);

class SalesTab extends ConsumerStatefulWidget {
  const SalesTab({super.key});

  @override
  ConsumerState<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends ConsumerState<SalesTab> {
  String view = 'month';
  DateTime selectedWeek = DateTime.now();
  DateTime selectedMonth = DateTime.now();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DateTime getStartOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  double sum(List<double> list) => list.fold(0, (total, value) => total + value);

  List<double> getWeekSales(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime base,
  ) {
    final start = getStartOfWeek(base);
    final result = List<double>.filled(7, 0);
    for (final doc in docs) {
      final data = doc.data();
      final price = data['price'];
      final date = data['date'];
      if (price is! num || date is! Timestamp) continue;
      final saleDate = date.toDate();
      if (!saleDate.isBefore(start) &&
          saleDate.isBefore(start.add(const Duration(days: 7)))) {
        result[saleDate.weekday - 1] += price.toDouble();
      }
    }
    return result;
  }

  List<double> getMonthSales(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime base,
  ) {
    final days = DateTime(base.year, base.month + 1, 0).day;
    final result = List<double>.filled(days, 0);
    for (final doc in docs) {
      final data = doc.data();
      final price = data['price'];
      final date = data['date'];
      if (price is! num || date is! Timestamp) continue;
      final saleDate = date.toDate();
      if (saleDate.year == base.year && saleDate.month == base.month) {
        result[saleDate.day - 1] += price.toDouble();
      }
    }
    return result;
  }

  Future<void> addSales() async {
    final uid = _uid;
    if (uid == null) {
      _showMessage('ログイン状態を確認できませんでした');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final plan = userDoc.data()?['plan'] ?? 'free';
      final salesCollection = await currentUserSalesCollection();
      final salesSnapshot = await salesCollection.get();
      if (plan == 'free' && salesSnapshot.docs.length >= 3) {
        _showMessage('無料プランは売上3件までです');
        return;
      }
      if (!mounted) return;
      await _showSalesSheet(salesCollection: salesCollection);
    } catch (_) {
      _showMessage('売上情報の確認に失敗しました。もう一度お試しください');
    }
  }

  Future<void> editSales(
    QueryDocumentSnapshot<Map<String, dynamic>> sale,
  ) async {
    final data = sale.data();
    final price = data['price'];
    final date = data['date'];
    if (price is! num || date is! Timestamp) {
      _showMessage('この売上データは編集できません');
      return;
    }

    try {
      final salesCollection = await currentUserSalesCollection();
      if (!mounted) return;
      await _showSalesSheet(
        salesCollection: salesCollection,
        saleId: sale.id,
        initialPrice: price.toDouble(),
        initialMenu: data['menu'] as String? ?? '',
        initialDate: date.toDate(),
      );
    } catch (_) {
      _showMessage('売上情報を開けませんでした');
    }
  }

  Future<void> _showSalesSheet({
    required CollectionReference<Map<String, dynamic>> salesCollection,
    String? saleId,
    double? initialPrice,
    String initialMenu = '',
    DateTime? initialDate,
  }) {
    final isEditing = saleId != null;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SalesEditorSheet(
        title: isEditing ? '売上を編集' : '売上を記入',
        initialPrice: initialPrice,
        initialMenu: initialMenu,
        initialDate: initialDate ?? DateTime.now(),
        onSave: ({required price, required menu, required date}) async {
          final values = <String, dynamic>{
            'price': price,
            'menu': menu,
            'date': date,
            'updatedAt': FieldValue.serverTimestamp(),
          };
          if (isEditing) {
            await salesCollection.doc(saleId).update(values);
          } else {
            values['createdAt'] = FieldValue.serverTimestamp();
            await salesCollection.add(values);
          }
        },
        onDelete: isEditing
            ? () async => salesCollection.doc(saleId).delete()
            : null,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesStreamProvider);
    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: sales.hasValue && sales.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: addSales,
              backgroundColor: _darkBrown,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded),
              label: const Text('売上を記入'),
            )
          : null,
      body: sales.when(
        loading: () => const Center(child: CupertinoActivityIndicator(radius: 14)),
        error: (_, __) => _SalesErrorState(
          onRetry: () => ref.invalidate(salesStreamProvider),
        ),
        data: (docs) => docs.isEmpty
            ? _SalesEmptyState(onAdd: addSales)
            : _buildSalesContent(docs),
      ),
    );
  }

  Widget _buildSalesContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final weekSales = getWeekSales(docs, selectedWeek);
    final monthSales = getMonthSales(docs, selectedMonth);
    final now = DateTime.now();
    final currentMonthTotal = sum(getMonthSales(docs, now));
    final currentMonthCount = docs.where((doc) {
      final date = doc.data()['date'];
      return date is Timestamp &&
          date.toDate().year == now.year &&
          date.toDate().month == now.month;
    }).length;

    return RefreshIndicator(
      color: _darkBrown,
      onRefresh: () async {
        await ref.refresh(salesStreamProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          _MonthlyHeroCard(
            total: currentMonthTotal,
            month: now.month,
            count: currentMonthCount,
          ),
          const SizedBox(height: 24),
          _ChartCard(
            view: view,
            total: view == 'week' ? sum(weekSales) : sum(monthSales),
            child: Column(
              children: [
                CupertinoSlidingSegmentedControl<String>(
                  groupValue: view,
                  backgroundColor: _beige.withOpacity(0.22),
                  thumbColor: Colors.white,
                  children: const {
                    'week': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('週間'),
                    ),
                    'month': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text('月間'),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) setState(() => view = value);
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 210,
                  child: view == 'week'
                      ? _weekChart(weekSales)
                      : _monthChart(monthSales),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '売上履歴',
                style: TextStyle(
                  color: _darkBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${docs.length}件',
                style: const TextStyle(color: _mutedBrown, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...docs.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SalesHistoryCard(
                document: doc,
                onTap: () => editSales(doc),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PlanAdvertisement(uid: _uid),
        ],
      ),
    );
  }

  Widget _weekChart(List<double> data) {
    final maxValue = data.fold<double>(0, (max, value) => value > max ? value : max);
    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 10000 : maxValue * 1.25,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: _beige.withOpacity(0.25),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['月', '火', '水', '木', '金', '土', '日'];
                final index = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[index],
                    style: const TextStyle(color: _mutedBrown, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          7,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index],
                width: 18,
                color: _roseBrown,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue == 0 ? 10000 : maxValue * 1.25,
                  color: _beige.withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthChart(List<double> data) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: _beige.withOpacity(0.25),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${value.toInt() + 1}',
                  style: const TextStyle(color: _mutedBrown, fontSize: 11),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index]),
            ),
            isCurved: true,
            color: _roseBrown,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_roseBrown.withOpacity(0.25), _roseBrown.withOpacity(0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyHeroCard extends StatelessWidget {
  const _MonthlyHeroCard({
    required this.total,
    required this.month,
    required this.count,
  });

  final double total;
  final int month;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5D5CE), Color(0xFFCBB0A6)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _darkBrown.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$month月の売上',
                style: TextStyle(
                  color: _darkBrown.withOpacity(0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count件',
                  style: const TextStyle(
                    color: _darkBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '¥${_formatAmount(total)}',
              style: const TextStyle(
                color: _darkBrown,
                fontSize: 42,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            '今月も素敵なサロンワークを。',
            style: TextStyle(color: _darkBrown.withOpacity(0.62), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.view, required this.total, required this.child});

  final String view;
  final double total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _beige.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: _darkBrown.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            view == 'week' ? '週間レポート' : '月間レポート',
            style: const TextStyle(
              color: _mutedBrown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '¥${_formatAmount(total)}',
            style: const TextStyle(
              color: _darkBrown,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SalesHistoryCard extends StatelessWidget {
  const _SalesHistoryCard({required this.document, required this.onTap});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final price = data['price'];
    final date = data['date'];
    final saleDate = date is Timestamp ? date.toDate() : null;
    final menu = (data['menu'] as String?)?.trim();

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _beige.withOpacity(0.26)),
            boxShadow: [
              BoxShadow(
                color: _darkBrown.withOpacity(0.055),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _beige.withOpacity(0.27),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.spa_outlined, color: _darkBrown, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu?.isNotEmpty == true ? menu! : 'メニュー未設定',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      saleDate == null
                          ? '日付未設定'
                          : '${saleDate.year}.${saleDate.month.toString().padLeft(2, '0')}.${saleDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: _mutedBrown, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${_formatAmount(price is num ? price.toDouble() : 0)}',
                    style: const TextStyle(
                      color: _darkBrown,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Icon(Icons.chevron_right_rounded, color: _roseBrown, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesEmptyState extends StatelessWidget {
  const _SalesEmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(color: Color(0xFFF0E5E0), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.chart_bar_alt_fill, color: _roseBrown, size: 34),
            ),
            const SizedBox(height: 22),
            const Text(
              '売上データはまだありません',
              style: TextStyle(color: _darkBrown, fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('最初の売上を記録しましょう', style: TextStyle(color: _mutedBrown)),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _darkBrown),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('最初の売上を記入'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesErrorState extends StatelessWidget {
  const _SalesErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle, color: _roseBrown, size: 48),
            const SizedBox(height: 18),
            const Text(
              '読み込みに失敗しました',
              style: TextStyle(color: _darkBrown, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '通信環境を確認して、もう一度お試しください',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedBrown),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanAdvertisement extends StatelessWidget {
  const _PlanAdvertisement({required this.uid});
  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data()?['plan'] == 'pro') {
          return const SizedBox.shrink();
        }
        return const Column(
          children: [
            Text('無料プランをご利用中', style: TextStyle(fontSize: 12, color: _mutedBrown)),
            SizedBox(height: 8),
            Center(child: BannerAdWidget()),
          ],
        );
      },
    );
  }
}

String _formatAmount(double value) {
  final digits = value.round().toString();
  return digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}
