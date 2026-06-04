import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_menu.dart';
import '../providers/web_booking_provider.dart';
import '../providers/web_shop_provider.dart';
import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

class WebBookingPage extends ConsumerWidget {
  const WebBookingPage({super.key, required this.shopName});

  final String shopName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(webShopProvider(shopName));
    final bookingState = ref.watch(webBookingProvider);
    final bookingController = ref.read(webBookingProvider.notifier);

    return WebPageShell(
      child: shopAsync.when(
        data: (shop) {
          if (shop == null || !shop.isWebPublished) {
            return const Center(child: Text('店舗が見つかりません。'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    WebRoutePaths.shop(shop.shopName),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('店舗ページへ戻る'),
                ),
                const SizedBox(height: 8),
                Text(
                  '${shop.shopName} の予約',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: webBlack,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '必要事項を入力して予約を送信してください。',
                  style: TextStyle(color: webMuted),
                ),
                const SizedBox(height: 24),
                WebCard(
                  child: Column(
                    children: [
                      _BookingTextField(
                        label: 'お名前',
                        icon: Icons.person_outline,
                        onChanged: bookingController.setCustomerName,
                      ),
                      const SizedBox(height: 16),
                      _BookingTextField(
                        label: '電話番号',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        onChanged: bookingController.setCustomerPhone,
                      ),
                      const SizedBox(height: 16),
                      ref.watch(webMenusProvider(shop.shopId)).when(
                        data: (menus) => _MenuDropdown(
                          menus: menus,
                          selectedMenuId: bookingState.menuId,
                          onChanged: (value) {
                            if (value != null) {
                              bookingController.setMenuId(value);
                            }
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('メニューの読み込みに失敗しました。'),
                      ),
                      const SizedBox(height: 16),
                      _DateTimeSelector(
                        selectedDateTime: bookingState.reservationDateTime,
                        onChanged: bookingController.setReservationDateTime,
                      ),
                      if (bookingState.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          bookingState.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 22),
                      WebPrimaryButton(
                        label: '予約する',
                        isLoading: bookingState.isSubmitting,
                        onPressed: bookingState.canSubmit
                            ? () async {
                                final reservationId =
                                    await bookingController.submit(shop.shopId);
                                if (reservationId == null || !context.mounted) {
                                  return;
                                }
                                final query = Uri(queryParameters: {
                                  'shopName': shop.shopName,
                                  'reservationId': reservationId,
                                  'reservationDateTime': bookingState
                                      .reservationDateTime!
                                      .toIso8601String(),
                                }).query;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/complete?$query',
                                  (_) => false,
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('予約ページの読み込みに失敗しました。')),
      ),
    );
  }
}

class _BookingTextField extends StatelessWidget {
  const _BookingTextField({
    required this.label,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: webLightBeige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MenuDropdown extends StatelessWidget {
  const _MenuDropdown({
    required this.menus,
    required this.selectedMenuId,
    required this.onChanged,
  });

  final List<WebMenu> menus;
  final String? selectedMenuId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedMenuId,
      decoration: InputDecoration(
        labelText: 'メニュー選択',
        prefixIcon: const Icon(Icons.content_cut),
        filled: true,
        fillColor: webLightBeige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: menus
          .map(
            (menu) => DropdownMenuItem(
              value: menu.menuId,
              child: Text('${menu.name} / ¥${menu.price} / ${menu.duration}分'),
            ),
          )
          .toList(),
      onChanged: menus.isEmpty ? null : onChanged,
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  const _DateTimeSelector({
    required this.selectedDateTime,
    required this.onChanged,
  });

  final DateTime? selectedDateTime;
  final ValueChanged<DateTime> onChanged;

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}年${month}月${day}日 $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final label = selectedDateTime == null
        ? '日時を選択'
        : _formatDateTime(selectedDateTime!);

    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: now.add(const Duration(days: 1)),
          firstDate: now,
          lastDate: now.add(const Duration(days: 120)),
          locale: const Locale('ja'),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 10, minute: 0),
        );
        if (time == null) return;

        onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      icon: const Icon(Icons.event_available),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: webBlack,
        side: const BorderSide(color: webBeige),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
