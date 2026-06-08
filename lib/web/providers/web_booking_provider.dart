import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_business_hours.dart';
import '../models/web_reservation.dart';
import '../services/web_booking_service.dart';

class WebBookingState {
  const WebBookingState({
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.menuId,
    this.reservationDateTime,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String? menuId;
  final DateTime? reservationDateTime;
  final bool isSubmitting;
  final String? errorMessage;

  bool get canSubmit =>
      customerName.trim().isNotEmpty &&
      customerPhone.trim().isNotEmpty &&
      _isValidEmail(customerEmail) &&
      menuId != null &&
      reservationDateTime != null &&
      !isSubmitting;

  WebBookingState copyWith({
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? menuId,
    DateTime? reservationDateTime,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WebBookingState(
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      menuId: menuId ?? this.menuId,
      reservationDateTime: reservationDateTime ?? this.reservationDateTime,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final webBookingServiceProvider = Provider<WebBookingService>((ref) {
  return WebBookingService();
});

final webReservationProvider =
    FutureProvider.autoDispose.family<WebReservation?, String>((
  ref,
  reservationId,
) {
  return ref.watch(webBookingServiceProvider).fetchReservation(reservationId);
});

final webBookingProvider =
    StateNotifierProvider.autoDispose<WebBookingController, WebBookingState>((
  ref,
) {
  return WebBookingController(ref.watch(webBookingServiceProvider));
});

class WebBookingController extends StateNotifier<WebBookingState> {
  WebBookingController(this._bookingService) : super(const WebBookingState());

  final WebReservationCreator _bookingService;

  void setCustomerName(String value) {
    state = state.copyWith(customerName: value, clearError: true);
  }

  void setCustomerPhone(String value) {
    state = state.copyWith(customerPhone: value, clearError: true);
  }

  void setCustomerEmail(String value) {
    state = state.copyWith(customerEmail: value, clearError: true);
  }

  void setMenuId(String value) {
    state = state.copyWith(menuId: value, clearError: true);
  }

  void setReservationDateTime(DateTime value) {
    state = state.copyWith(reservationDateTime: value, clearError: true);
  }

  bool setReservationDate(
    DateTime value, {
    required Iterable<int> closedWeekdays,
  }) {
    if (isClosedDay(value, closedWeekdays)) {
      state = state.copyWith(errorMessage: closedDayBookingMessage);
      return false;
    }

    final current = state.reservationDateTime;
    state = state.copyWith(
      reservationDateTime: DateTime(
        value.year,
        value.month,
        value.day,
        current?.hour ?? 10,
        current?.minute ?? 0,
      ),
      clearError: true,
    );
    return true;
  }

  void showClosedDayError() {
    state = state.copyWith(errorMessage: closedDayBookingMessage);
  }

  void setReservationTime(TimeOfDay value) {
    final current = state.reservationDateTime;
    final now = DateTime.now();
    final baseDate = current ?? now.add(const Duration(days: 1));
    state = state.copyWith(
      reservationDateTime: DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        value.hour,
        value.minute,
      ),
      clearError: true,
    );
  }

  Future<String?> submit(
    String shopId, {
    required Iterable<int> closedWeekdays,
  }) async {
    if (!state.canSubmit) {
      state = state.copyWith(
        errorMessage:
            'お名前・電話番号・正しいメールアドレス・メニュー・日時を入力してください。',
      );
      return null;
    }

    final selectedDate = state.reservationDateTime!;
    if (isClosedDay(selectedDate, closedWeekdays)) {
      state = state.copyWith(errorMessage: closedDayBookingMessage);
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final reservationId = await _bookingService.createReservation(
        WebReservation(
          reservationId: '',
          shopId: shopId,
          menuId: state.menuId!,
          customerName: state.customerName.trim(),
          customerPhone: state.customerPhone.trim(),
          customerEmail: state.customerEmail.trim(),
          reservationDateTime: state.reservationDateTime!,
          status: 'pending',
          source: 'web',
          isNotified: false,
          createdAt: null,
        ),
      );
      state = state.copyWith(isSubmitting: false);
      return reservationId;
    } catch (error) {
      final isClosedDayError =
          error.toString().contains(closedDayBookingMessage);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: isClosedDayError
            ? closedDayBookingMessage
            : '予約の保存に失敗しました。時間をおいて再度お試しください。',
      );
      return null;
    }
  }
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
}
