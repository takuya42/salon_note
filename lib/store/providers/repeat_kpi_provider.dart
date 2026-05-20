import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RepeatKpi {
  const RepeatKpi({
    required this.repeatRate,
  });

  final double repeatRate;
}

final repeatKpiProvider = StreamProvider.autoDispose<RepeatKpi>((ref) {
  final db = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return Stream.value(
      const RepeatKpi(
        repeatRate: 0,
      ),
    );
  }

  return db.collection('users').doc(uid).snapshots().asyncExpand((userDoc) {
    final shopId = userDoc.data()?['shopId'];

    if (shopId == null) {
      return Stream.value(
        const RepeatKpi(
          repeatRate: 0,
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

RepeatKpi _buildRepeatKpi(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
  final visitsByCustomer = <String, List<DateTime>>{};
  final now = DateTime.now();

  for (final doc in snapshot.docs) {
    final data = doc.data();

    final customerId = data['customerId'] as String?;

    if (customerId == null || customerId.isEmpty) {
      continue;
    }

    final rawTime = data['startTime'] ?? data['start'];

    DateTime? visitAt;

    if (rawTime is Timestamp) {
      visitAt = rawTime.toDate();
    } else if (rawTime is DateTime) {
      visitAt = rawTime;
    }

    if (visitAt == null) {
      continue;
    }


    if (visitAt.month != now.month ||
        visitAt.year != now.year) {
      continue;
    }

    visitsByCustomer.putIfAbsent(customerId, () => []).add(visitAt);
  }

  int repeaterCount = 0;
  int totalCustomerCount = visitsByCustomer.length;

  visitsByCustomer.forEach((_, visits) {
    visits.sort();

    bool hasReturnWithin30Days = false;

    for (var i = 1; i < visits.length; i++) {
      final diff = visits[i]
          .difference(visits[i - 1])
          .inDays;

      if (diff <= 30) {
        hasReturnWithin30Days = true;
        break;
      }
    }

    if (hasReturnWithin30Days) {
      repeaterCount++;
    }
  });

  final repeatRate = totalCustomerCount == 0
      ? 0.0
      : (repeaterCount / totalCustomerCount) * 100;

  return RepeatKpi(
    repeatRate: repeatRate,
  );
}