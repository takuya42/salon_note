import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sales_model.dart';

final salesStreamProvider = StreamProvider.autoDispose<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('売上データを読み込むにはログインが必要です。');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('sales')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

final salesProvider =
    StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  return SalesNotifier();
});

class SalesState {
  final List<Sales> salesList;

  SalesState({required this.salesList});

  Map<String, dynamic> toJson() {
    return {
      "salesList": salesList.map((e) => e.toJson()).toList(),
    };
  }

  factory SalesState.fromJson(Map<String, dynamic> json) {
    return SalesState(
      salesList: (json["salesList"] as List)
          .map((e) => Sales.fromJson(e))
          .toList(),
    );
  }

  SalesState copyWith({
    List<Sales>? salesList,
  }) {
    return SalesState(
      salesList: salesList ?? this.salesList,
    );
  }
}

class SalesNotifier extends StateNotifier<SalesState> {
  SalesNotifier() : super(SalesState(salesList: []));

  /// ===== load =====
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("sales");

    if (data != null) {
      state = SalesState.fromJson(jsonDecode(data));
    }
  }

  /// ===== save =====
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("sales", jsonEncode(state.toJson()));
  }

  /// ===== 追加 =====
  void addSales(double price, String menu, DateTime date) {
    final sale = Sales(
      price: price,
      menu: menu,
      date: date,
    );

    state = state.copyWith(
      salesList: [sale, ...state.salesList],
    );

    save();
  }

  /// ===== 削除 =====
  void deleteSales(int index) {
    final list = [...state.salesList];
    list.removeAt(index);

    state = state.copyWith(salesList: list);
    save();
  }

  /// ===== 今日 =====
  double todaySales() {
    final now = DateTime.now();

    return state.salesList
        .where((s) =>
    s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day)
        .fold(0, (sum, e) => sum + e.price);
  }

  /// ===== 週間 =====
  List<double> getWeekSales(DateTime baseDate) {
    final start = baseDate.subtract(Duration(days: baseDate.weekday - 1));

    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));

      return state.salesList
          .where(
            (s) =>
                s.date.year == day.year &&
                s.date.month == day.month &&
                s.date.day == day.day,
          )
          .fold(0, (sum, e) => sum + e.price);
    });
  }

  /// ===== 月間 =====
  List<double> getMonthSales(DateTime baseDate) {
    final days = DateTime(baseDate.year, baseDate.month + 1, 0).day;

    return List.generate(days, (i) {
      final day = DateTime(baseDate.year, baseDate.month, i + 1);

      return state.salesList
          .where(
            (s) =>
                s.date.year == day.year &&
                s.date.month == day.month &&
                s.date.day == day.day,
          )
          .fold(0, (sum, e) => sum + e.price);
    });
  }
}