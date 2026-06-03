import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_reservation.dart';
import '../services/web_booking_service.dart';

class WebBookingState {
  const WebBookingState({
    this.customerName = '',
    this.customerPhone = '',
    this.menuId,
    this.reservationDateTime,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String customerName;
  final String customerPhone;
  final String? menuId;
  final DateTime? reservationDateTime;
  final bool isSubmitting;
  final String? errorMessage;

  bool get canSubmit =>
      customerName.trim().isNotEmpty &&
      customerPhone.trim().isNotEmpty &&
      menuId != null &&
      reservationDateTime != null &&
      !isSubmitting;

  WebBookingState copyWith({
    String? customerName,
    String? customerPhone,
    String? menuId,
    DateTime? reservationDateTime,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WebBookingState(
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
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

final webReservationProvider = FutureProvider.autoDispose.family<WebReservation?, String>((ref, reservationId) {
  return ref.watch(webBookingServiceProvider).fetchReservation(reservationId);
});

final webBookingProvider = StateNotifierProvider.autoDispose<WebBookingController, WebBookingState>((ref) {
  return WebBookingController(ref.watch(webBookingServiceProvider));
});

class WebBookingController extends StateNotifier<WebBookingState> {
  WebBookingController(this._bookingService) : super(const WebBookingState());

  final WebBookingService _bookingService;

  void setCustomerName(String value) {
    state = state.copyWith(customerName: value, clearError: true);
  }

  void setCustomerPhone(String value) {
    state = state.copyWith(customerPhone: value, clearError: true);
  }

  void setMenuId(String value) {
    state = state.copyWith(menuId: value, clearError: true);
  }

  void setReservationDateTime(DateTime value) {
    state = state.copyWith(reservationDateTime: value, clearError: true);
  }

  Future<String?> submit(String shopId) async {
    if (!state.canSubmit) {
      state = state.copyWith(errorMessage: 'お名前・電話番号・メニュー・日時を入力してください。');
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
          reservationDateTime: state.reservationDateTime!,
          status: '予約受付',
          source: 'web',
          isNotified: false,
          createdAt: null,
        ),
      );
      state = state.copyWith(isSubmitting: false);
      return reservationId;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '予約の保存に失敗しました。時間をおいて再度お試しください。',
      );
      return null;
    }
  }
}
