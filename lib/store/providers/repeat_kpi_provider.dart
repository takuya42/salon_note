import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RepeatKpi {
  const RepeatKpi({
    required this.repeatRate,
    required this.newCustomerCount,
    required this.repeaterCount,
    required this.lostCustomerCount,
    required this.averageVisitCycleDays,
  });

  final double repeatRate;
  final int newCustomerCount;
  final int repeaterCount;
  final int lostCustomerCount;
  final double averageVisitCycleDays;
}

final repeatKpiProvider = StreamProvider.autoDispose<RepeatKpi>((ref) {
  final db = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return Stream.value(
      const RepeatKpi(
        repeatRate: 0,
        newCustomerCount: 0,
        repeaterCount: 0,
        lostCustomerCount: 0,
        averageVisitCycleDays: 0,
      ),
    );
  }

  return db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
    final shopId = userDoc.data()?['shopId'];
    if (shopId == null) {
      return Stream.value(
        const RepeatKpi(
          repeatRate: 0,
          newCustomerCount: 0,
          repeaterCount: 0,
          lostCustomerCount: 0,
          averageVisitCycleDays: 0,
        ),
      );
    }

    return db
        .collection('shops')
        .doc(shopId)
        .collection('reservations')
        .snapshots()
        .map(_buildRepeatKpi);
  });
});

RepeatKpi _buildRepeatKpi(QuerySnapshot<Map<String, dynamic>> snapshot) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final ninetyDaysAgo = now.subtract(const Duration(days: 90));

  final visitsByCustomer = <String, List<DateTime>>{};

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final customerId = data['customerId'] as String?;
    if (customerId == null || customerId.isEmpty) continue;

    final rawTime = data['startTime'] ?? data['start'];
    DateTime? visitAt;
    if (rawTime is Timestamp) {
      visitAt = rawTime.toDate();
    } else if (rawTime is DateTime) {
      visitAt = rawTime;
    }
    if (visitAt == null) continue;

    visitsByCustomer.putIfAbsent(customerId, () => []).add(visitAt);
  }

  int newCustomerCount = 0;
  int repeaterCount = 0;
  int lostCustomerCount = 0;
  final visitCycles = <int>[];

  visitsByCustomer.forEach((_, visits) {
    visits.sort();

    final firstVisit = visits.first;
    final lastVisit = visits.last;

    if (firstVisit.isAfter(monthStart) || firstVisit.isAtSameMomentAs(monthStart)) {
      newCustomerCount += 1;
    }

    if (visits.length >= 2) {
      bool hasReturnWithin30Days = false;
      for (var i = 1; i < visits.length; i++) {
        final diff = visits[i].difference(visits[i - 1]).inDays;
        if (diff <= 30) {
          hasReturnWithin30Days = true;
        }
        if (diff > 0) {
          visitCycles.add(diff);
        }
      }
      if (hasReturnWithin30Days || lastVisit.isAfter(thirtyDaysAgo)) {
        repeaterCount += 1;
      }
    }

    if (lastVisit.isBefore(ninetyDaysAgo)) {
      lostCustomerCount += 1;
    }
  });

  final repeatBase = newCustomerCount + repeaterCount;
  final repeatRate = repeatBase == 0 ? 0.0 : (repeaterCount / repeatBase) * 100;

  final avgCycle = visitCycles.isEmpty
      ? 0.0
      : visitCycles.reduce((a, b) => a + b) / visitCycles.length;

  return RepeatKpi(
    repeatRate: repeatRate,
    newCustomerCount: newCustomerCount,
    repeaterCount: repeaterCount,
    lostCustomerCount: lostCustomerCount,
    averageVisitCycleDays: avgCycle,
  );
}
