import 'package:flutter/material.dart'; // ←これ追加🔥
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ReservationModel {
  final String id;
  final String customerName;
  final String menu;
  final DateTime startTime;
  final DateTime endTime;

  ReservationModel({
    required this.id,
    required this.customerName,
    required this.menu,
    required this.startTime,
    required this.endTime,
  });

  factory ReservationModel.fromMap(String id, Map<String, dynamic> map) {
    return ReservationModel(
      id: id,
      customerName: map['customerName'] ?? '',
      menu: map['menu'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
    );
  }

  Appointment toAppointment() {
    return Appointment(
      startTime: startTime,
      endTime: endTime,
      subject: '$customerName（$menu）',
      color: const Color(0xFFFF9800),
    );
  }
}