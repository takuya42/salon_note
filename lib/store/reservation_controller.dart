import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ReservationController {

  final List<Appointment> appointments = [];

  /// 予約追加
  void addReservation({
    required String name,
    required DateTime start,
    required DateTime end,
  }) {

    appointments.add(
      Appointment(
        startTime: start,
        endTime: end,
        subject: name,
        color: Colors.orange,
      ),
    );

  }

  /// 削除
  void deleteReservation(Appointment appointment) {

    appointments.remove(appointment);

  }

  /// 15分丸め
  DateTime round15(DateTime time) {

    int minute = (time.minute ~/ 15) * 15;

    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      minute,
    );
  }

  /// 時間フォーマット
  String formatTime(DateTime time) {

    return "${time.hour}:${time.minute.toString().padLeft(2,'0')}";

  }

}