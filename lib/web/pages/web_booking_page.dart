import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_menu.dart';
import '../providers/web_booking_provider.dart';
import '../providers/web_shop_provider.dart';
import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

class WebBookingPage extends ConsumerStatefulWidget {
  const WebBookingPage({
    super.key,
    required this.shopId,
    this.initialMenuId,
  });

  final String shopId;
  final String? initialMenuId;

  @override
  ConsumerState<WebBookingPage> createState() => _WebBookingPageState();
}

class _WebBookingPageState extends ConsumerState<WebBookingPage> {
  bool _appliedInitialMenuId = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedInitialMenuId) {
      return;
    }

    final initialMenuId = widget.initialMenuId?.trim();
    if (initialMenuId == null || initialMenuId.isEmpty) {
      _appliedInitialMenuId = true;
      return;
    }

    _appliedInitialMenuId = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(webBookingProvider.notifier).setMenuId(initialMenuId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(webShopByIdProvider(widget.shopId));
    final bookingState = ref.watch(webBookingProvider);
    final bookingController = ref.read(webBookingProvider.notifier);

    return WebPageShell(
      child: shopAsync.when(
        data: (shop) {
          if (shop == null || !shop.isWebPublished) {
            return const Center(child: Text('店舗が見つかりません。'));
          }
          if (!shop.isWebBookingEnabled) {
            return const Center(child: Text('現在Web予約を受け付けていません。'));
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BookingInfoRow(label: '店舗名', value: shop.shopName),
                      const SizedBox(height: 18),
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
                      _BookingTextField(
                        label: 'メールアドレス',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onChanged: bookingController.setCustomerEmail,
                      ),
                      const SizedBox(height: 16),
                      ref.watch(webMenusProvider(shop.shopId)).when(
                            data: (menus) {
                              WebMenu? selectedMenu;
                              for (final menu in menus) {
                                if (menu.menuId == bookingState.menuId) {
                                  selectedMenu = menu;
                                  break;
                                }
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _MenuDropdown(
                                    menus: menus,
                                    selectedMenuId: bookingState.menuId,
                                    onChanged: (value) {
                                      if (value != null) {
                                        bookingController.setMenuId(value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _SelectedMenuSummary(menu: selectedMenu),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) =>
                                const Text('メニューの読み込みに失敗しました。'),
                          ),
                      const SizedBox(height: 16),
                      _DateSelector(
                        selectedDateTime: bookingState.reservationDateTime,
                        onChanged: bookingController.setReservationDate,
                      ),
                      const SizedBox(height: 12),
                      _TimeSelector(
                        selectedDateTime: bookingState.reservationDateTime,
                        onChanged: bookingController.setReservationTime,
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
                        label: '予約確定',
                        isLoading: bookingState.isSubmitting,
                        onPressed: bookingState.canSubmit
                            ? () async {
                                final reservationId =
                                    await bookingController.submit(shop.shopId);
                                if (reservationId == null || !context.mounted) {
                                  return;
                                }
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/complete',
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

class _BookingInfoRow extends StatelessWidget {
  const _BookingInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(
              color: webMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: webDarkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingTextField extends StatelessWidget {
  const _BookingTextField({
    required this.label,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
    this.autofillHints,
  });

  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: '$label（必須）',
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
    final selectedExists =
        selectedMenuId == null || menus.any((menu) => menu.menuId == selectedMenuId);

    return DropdownButtonFormField<String>(
      value: selectedExists ? selectedMenuId : null,
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

class _SelectedMenuSummary extends StatelessWidget {
  const _SelectedMenuSummary({required this.menu});

  final WebMenu? menu;

  @override
  Widget build(BuildContext context) {
    if (menu == null) {
      return const Text(
        'メニューを選択すると料金と施術時間が表示されます。',
        style: TextStyle(color: webMuted),
      );
    }

    final selectedMenu = menu!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: webLightBeige,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _BookingInfoRow(label: 'メニュー名', value: selectedMenu.name),
            const SizedBox(height: 8),
            _BookingInfoRow(
              label: '料金',
              value: '¥${_formatNumber(selectedMenu.price)}',
            ),
            const SizedBox(height: 8),
            _BookingInfoRow(label: '施術時間', value: '${selectedMenu.duration}分'),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDateTime,
    required this.onChanged,
  });

  final DateTime? selectedDateTime;
  final ValueChanged<DateTime> onChanged;

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}年$month月$day日';
  }

  @override
  Widget build(BuildContext context) {
    final label = selectedDateTime == null
        ? '予約日を選択（必須）'
        : _formatDate(selectedDateTime!);

    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDateTime ?? now.add(const Duration(days: 1)),
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 120)),
          locale: const Locale('ja'),
        );
        if (date == null) return;
        onChanged(date);
      },
      icon: const Icon(Icons.event_outlined),
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

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.selectedDateTime,
    required this.onChanged,
  });

  final DateTime? selectedDateTime;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = selectedDateTime == null
        ? '予約時間を選択（必須）'
        : '${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}';

    return OutlinedButton.icon(
      onPressed: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedDateTime == null
              ? const TimeOfDay(hour: 10, minute: 0)
              : TimeOfDay.fromDateTime(selectedDateTime!),
        );
        if (time == null) return;
        onChanged(time);
      },
      icon: const Icon(Icons.schedule_outlined),
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

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
}
