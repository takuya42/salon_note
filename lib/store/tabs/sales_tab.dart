import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/banner_ad_widget.dart';

String get uid => FirebaseAuth.instance.currentUser!.uid;

class SalesTab extends ConsumerStatefulWidget {
  const SalesTab({super.key});

  @override
  ConsumerState<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends ConsumerState<SalesTab> {

  String view = "week";

  DateTime selectedWeek = DateTime.now();
  DateTime selectedMonth = DateTime.now();
  DateTime inputDate = DateTime.now();

  /// ===== 週間開始 =====
  DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  double sum(List<double> list) =>
      list.fold(0, (sum, e) => sum + e);

  /// ===== 週間 =====
  List<double> getWeekSales(List<QueryDocumentSnapshot> docs, DateTime base) {

    DateTime start = getStartOfWeek(base);
    List<double> result = List.filled(7, 0);

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['price'] == null || data['date'] == null) continue;

      DateTime d = (data['date'] as Timestamp).toDate();

      if (d.isAfter(start.subtract(const Duration(days: 1))) &&
          d.isBefore(start.add(const Duration(days: 7)))) {

        int index = d.weekday - 1;
        result[index] += (data['price'] as num).toDouble();
      }
    }

    return result;
  }

  /// ===== 月間 =====
  List<double> getMonthSales(List<QueryDocumentSnapshot> docs, DateTime base) {

    int days = DateTime(base.year, base.month + 1, 0).day;
    List<double> result = List.filled(days, 0);

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['price'] == null || data['date'] == null) continue;

      DateTime d = (data['date'] as Timestamp).toDate();

      if (d.year == base.year && d.month == base.month) {
        result[d.day - 1] += (data['price'] as num).toDouble();
      }
    }

    return result;
  }

  /// ===== 手動追加 =====
  void addSales() async{

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final plan = userDoc.data()?['plan'] ?? 'free';

    final salesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sales')
        .get();

    final salesCount = salesSnapshot.docs.length;

    if (plan == 'free' && salesCount >= 3) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("無料プランは売上3件までです"),
        ),
      );

      return;
    }

    TextEditingController priceController = TextEditingController();
    TextEditingController menuController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context){

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text("売上入力"),
              const SizedBox(height: 20),

              ListTile(
                title: const Text("日付"),
                subtitle: Text(
                  "${inputDate.year}/${inputDate.month}/${inputDate.day}",
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: inputDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );

                  if(picked != null){
                    setState(() {
                      inputDate = picked;
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "金額",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: menuController,
                decoration: const InputDecoration(
                  labelText: "メニュー",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB08E85),
                ),
                onPressed: () async {

                  if(priceController.text.isEmpty) return;

                  double price =
                      double.tryParse(priceController.text) ?? 0;

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('sales')
                      .add({
                    'price': price,
                    'menu': menuController.text,
                    'date': inputDate,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                },
                child: const Text("保存"),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// ===== 削除 =====
  Future<void> deleteSales(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sales')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sales')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final weekSales = getWeekSales(docs, selectedWeek);
          final monthSales = getMonthSales(docs, selectedMonth);

          double todayTotal = 0;
          DateTime now = DateTime.now();

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            if (data['date'] == null || data['price'] == null) continue;

            DateTime d = (data['date'] as Timestamp).toDate();

            if (d.year == now.year &&
                d.month == now.month &&
                d.day == now.day) {
              todayTotal += (data['price'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("今日の売上"),
                  const SizedBox(height: 10),

                  Text(
                    "¥${todayTotal.toInt()}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB08E85),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBFA29A),
                    ),
                    onPressed: addSales,
                    icon: const Icon(Icons.add),
                    label: const Text("売上を記入"),
                  ),

                  const SizedBox(height: 20),

                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: view,
                    children: const {
                      "week": Text("週間"),
                      "month": Text("月間"),
                    },
                    onValueChanged: (value){
                      setState(() {
                        view = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Text(
                    view == "week"
                        ? "週間合計 ¥${sum(weekSales).toInt()}"
                        : "月間合計 ¥${sum(monthSales).toInt()}",
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 230,
                    child: view == "week"
                        ? weekChart(weekSales)
                        : monthChart(monthSales),
                  ),
                  const SizedBox(height: 20),

                  /// 🔥 広告
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .snapshots(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      final data =
                      snapshot.data!.data() as Map<String, dynamic>?;

                      final plan = data?['plan'] ?? 'free';

                      if (plan == 'pro') {
                        return const SizedBox();
                      }

                      return const Column(
                        children: [

                          Text(
                            "無料プランをご利用中",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          SizedBox(height: 6),

                          Center(
                            child: BannerAdWidget(),
                          ),

                          SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget weekChart(List<double> data){
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i){
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: Colors.orange,
              )
            ],
          );
        }),
      ),
    );
  }

  Widget monthChart(List<double> data){
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
                  (i) => FlSpot(i.toDouble(), data[i]),
            ),
            isCurved: true,
            color: Colors.orange,
          )
        ],
      ),
    );
  }
}