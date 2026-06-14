import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/web_reservation.dart';
import 'web_booking_callable.dart';
import 'web_reservation_extension_service.dart';

const duplicateReservationMessage =
    'この時間は既に予約されています。\n別の時間を選択してください。';

class DuplicateReservationException implements Exception {
  const DuplicateReservationException();

  @override
  String toString() => duplicateReservationMessage;
}

class WebReservationSaveException implements Exception {
  const WebReservationSaveException(this.code, this.userMessage);

  final String code;
  final String userMessage;

  @override
  String toString() => userMessage;
}

abstract interface class WebReservationCreator {
  Future<String> createReservation(WebReservation reservation);
}

class WebBookingService implements WebReservationCreator {
  WebBookingService({
    FirebaseFirestore? firestore,
    WebBookingCallable? callable,
    WebReservationExtensionService? extensionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _callable = callable ??
            WebBookingCallable(projectId: Firebase.app().options.projectId),
        _extensionService =
            extensionService ?? const WebNoopReservationExtensionService();

  final FirebaseFirestore _firestore;
  final WebBookingCallable _callable;
  final WebReservationExtensionService _extensionService;

  @override
  Future<String> createReservation(WebReservation reservation) async {
    final requestData = <String, dynamic>{
      'shopId': reservation.shopId,
      'menuId': reservation.menuId,
      'customerName': reservation.customerName,
      'customerPhone': reservation.customerPhone,
      'customerEmail': reservation.customerEmail,
      'reservationDateTimeMillis':
          reservation.reservationDateTime.millisecondsSinceEpoch,
    };
    debugPrint('[WebReservation] shopId=${reservation.shopId}');
    debugPrint('[WebReservation] menuId=${reservation.menuId}');
    debugPrint('[WebReservation] customerName=${reservation.customerName}');
    debugPrint('[WebReservation] customerEmail=${reservation.customerEmail}');
    debugPrint(
      '[WebReservation] reservationDateTime='
      '${reservation.reservationDateTime.toIso8601String()}',
    );
    debugPrint('[WebReservation] callable request=$requestData');

    try {
      final data = await _callable.call(requestData);
      final reservationId = data['reservationId'] as String?;
      if (reservationId == null || reservationId.isEmpty) {
        throw StateError('Reservation ID was not returned.');
      }

      final createdReservation = WebReservation(
        reservationId: reservationId,
        shopId: reservation.shopId,
        menuId: reservation.menuId,
        customerName: reservation.customerName,
        customerPhone: reservation.customerPhone,
        customerEmail: reservation.customerEmail,
        reservationDateTime: reservation.reservationDateTime,
        status: reservation.status,
        source: reservation.source,
        isNotified: reservation.isNotified,
        createdAt: reservation.createdAt,
      );
      await _extensionService.onReservationCreated(createdReservation);
      debugPrint('[WebReservation] saved reservationId=$reservationId');
      return reservationId;
    } on WebBookingCallableException catch (error) {
      debugPrint(
        '[WebReservation] Functions error code=${error.code} '
        'message=${error.message}',
      );
      if (error.code == 'already-exists') {
        throw const DuplicateReservationException();
      }
      throw WebReservationSaveException(
        error.code,
        _userMessageForCallableCode(error.code),
      );
    } catch (error, stackTrace) {
      debugPrint('[WebReservation] unexpected error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<WebReservation?> fetchReservation(String reservationId) async {
    final snapshot =
        await _firestore.collection('reservations').doc(reservationId).get();
    if (!snapshot.exists) return null;
    return WebReservation.fromFirestore(snapshot);
  }
}

String _userMessageForCallableCode(String code) {
  switch (code) {
    case 'permission-denied':
      return '予約を受け付けられませんでした。店舗の公開設定をご確認ください。';
    case 'failed-precondition':
      return 'この店舗またはメニューは現在予約を受け付けていません。';
    case 'invalid-argument':
      return '入力内容を確認し、もう一度お試しください。';
    case 'not-found':
      return '選択した店舗またはメニューが見つかりません。再読み込みしてください。';
    case 'unavailable':
      return '予約サービスに接続できません。通信状況を確認して再度お試しください。';
    default:
      return '予約を保存できませんでした。時間をおいて再度お試しください。';
  }
}
