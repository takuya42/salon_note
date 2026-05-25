import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


final reservationProvider =
StateNotifierProvider<ReservationNotifier, List<Appointment>>((ref) {
  return ReservationNotifier();
});

class ReservationNotifier extends StateNotifier<List<Appointment>> {
  ReservationNotifier() : super([]) {
    listenReservations();
  }

  final _db = FirebaseFirestore.instance;

  /// 🔥 縦表示
  String verticalText(String text) {
    return text.replaceAll(' ', '').split('').join('\n');
  }

  /// 🔥 リアルタイム取得
  void listenReservations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncExpand<QuerySnapshot<Map<String, dynamic>>>(
            (userDoc) {

          final shopId = userDoc.data()?['shopId'];

          if (shopId == null) {
            return const Stream.empty();
          }

          return _db
              .collection('shops')
              .doc(shopId)
              .collection('reservations')
              .orderBy('start')
              .snapshots();
        })
        .listen((snapshot) {

      state = snapshot.docs.map((doc) {

        final data = doc.data();

        return Appointment(
          startTime:
          (data['start'] as Timestamp).toDate(),

          endTime:
          (data['end'] as Timestamp).toDate(),

          /// 🔥 縦表示
          subject: verticalText(
            data['name'] ?? '',
          ),

          /// 🔥 色
          color: Color(
            data['color'] ??
                Colors.orange.value,
          ),

          /// 🔥 ID
          notes: doc.id,
        );
      }).toList();
    });
  }

  /// 🔥 追加
  Future<void> add(
      Appointment appt,
      ) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await _db
        .collection('users')
        .doc(user.uid)
        .get();

    final shopId =
    userDoc.data()?['shopId'];

    if (shopId == null) return;

    /// 🔥 Firestore保存
    await _db
        .collection('shops')
        .doc(shopId)
        .collection('reservations')
        .add({
      'name':
      appt.subject.replaceAll('\n', ''),

      'start': appt.startTime,

      'end': appt.endTime,

      'color': appt.color.value,

      'createdAt':
      FieldValue.serverTimestamp(),
    });

  }

  /// 🔥 削除
  Future<void> remove(
      Appointment appt,
      ) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await _db
        .collection('users')
        .doc(user.uid)
        .get();

    final shopId =
    userDoc.data()?['shopId'];

    final id = appt.notes;

    if (shopId != null && id != null) {

      /// 🔥 Firestore削除
      await _db
          .collection('shops')
          .doc(shopId)
          .collection('reservations')
          .doc(id)
          .delete();

    }
  }

  /// 🔥 更新
  Future<void> update(
      Appointment appt,
      ) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await _db
        .collection('users')
        .doc(user.uid)
        .get();

    final shopId =
    userDoc.data()?['shopId'];

    final id = appt.notes;

    if (shopId != null && id != null) {

      /// 🔥 Firestore更新
      await _db
          .collection('shops')
          .doc(shopId)
          .collection('reservations')
          .doc(id)
          .update({
        'name':
        appt.subject.replaceAll('\n', ''),

        'start': appt.startTime,

        'end': appt.endTime,

        'color': appt.color.value,
      });

    }
  }
}
