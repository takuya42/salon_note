import '../models/web_reservation.dart';

abstract class WebReservationExtensionService {
  const WebReservationExtensionService();

  Future<void> onReservationCreated(WebReservation reservation);
}

class WebNoopReservationExtensionService
    implements WebReservationExtensionService {
  const WebNoopReservationExtensionService();

  @override
  Future<void> onReservationCreated(WebReservation reservation) async {}
}

class WebCompositeReservationExtensionService
    implements WebReservationExtensionService {
  const WebCompositeReservationExtensionService(this.services);

  final List<WebReservationExtensionService> services;

  @override
  Future<void> onReservationCreated(WebReservation reservation) async {
    for (final service in services) {
      await service.onReservationCreated(reservation);
    }
  }
}
