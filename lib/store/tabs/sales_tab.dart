import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/banner_ad_widget.dart';
import '../providers/sales_provider.dart';
import '../widgets/sales_editor_sheet.dart';

class SalesTab extends ConsumerStatefulWidget {
  const SalesTab({super.key});

  @override
  ConsumerState<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends ConsumerState<SalesTab> {
  String view = 'week';
  DateTime selectedWeek = DateTime.now();
  DateTime selectedMonth = DateTime.now();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
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
      await _showSalesSheet(salesCollection);
    } catch (_) {
      _showMessage('売上情報の確認に失敗しました。もう一度お試しください');
    }
  }

  Future<void> _showSalesSheet(
    CollectionReference<Map<String, dynamic>> salesCollection,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SalesEditorSheet(
        initialDate: DateTime.now(),
        onSave: ({
          required double price,
          required String menu,
          required DateTime date,
        }) async {
          await salesCollection.add({
            'price': price,
            'menu': menu,
            'date': date,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }

  Future<void> deleteSales(String id) async {
    if (_uid == null) return;
    try {
      final salesCollection = await currentUserSalesCollection();
      await salesCollection.doc(id).delete();
    } catch (_) {
      _showMessage('削除に失敗しました');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesStreamProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: sales.when(
        loading: () => const Center(
          child: CupertinoActivityIndicator(radius: 14),
        ),
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
    var todayTotal = 0.0;

    for (final doc in docs) {
      final data = doc.data();
      final price = data['price'];
      final date = data['date'];
      if (price is! num || date is! Timestamp) continue;
      final saleDate = date.toDate();
      if (saleDate.year == now.year &&
          saleDate.month == now.month &&
          saleDate.day == now.day) {
        todayTotal += price.toDouble();
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(salesStreamProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('今日の売上', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            '¥${todayTotal.toInt()}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB08E85),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBFA29A),
              ),
              onPressed: addSales,
              icon: const Icon(Icons.add),
              label: const Text('売上を記入'),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: view,
            children: const {'week': Text('週間'), 'month': Text('月間')},
            onValueChanged: (value) {
              if (value != null) setState(() => view = value);
            },
          ),
          const SizedBox(height: 22),
          Text(
            view == 'week'
                ? '週間合計  ¥${sum(weekSales).toInt()}'
                : '月間合計  ¥${sum(monthSales).toInt()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: view == 'week'
                ? _weekChart(weekSales)
                : _monthChart(monthSales),
          ),
          const SizedBox(height: 20),
          _PlanAdvertisement(uid: _uid),
        ],
      ),
    );
  }

  Widget _weekChart(List<double> data) {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          7,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index],
                color: const Color(0xFFB08E85),
                borderRadius: BorderRadius.circular(5),
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
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (index) => FlSpot(index.toDouble(), data[index]),
            ),
            isCurved: true,
            color: const Color(0xFFB08E85),
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
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
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFF5EFEC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chart_bar_alt_fill,
                color: Color(0xFFB08E85),
                size: 31,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '売上データなし',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            const Text(
              'まだ売上データがありません',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
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
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: Color(0xFFB08E85),
              size: 48,
            ),
            const SizedBox(height: 18),
            const Text(
              '読み込みに失敗しました',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '通信環境を確認して、もう一度お試しください',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
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
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        if (snapshot.data?.data()?['plan'] == 'pro') {
          return const SizedBox.shrink();
        }
        return const Column(
          children: [
            Text(
              '無料プランをご利用中',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 6),
            Center(child: BannerAdWidget()),
            SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
