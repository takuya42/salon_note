import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/web_shop_provider.dart';
import '../widgets/web_design_widgets.dart';

class WebCompletePage extends ConsumerWidget {
  const WebCompletePage({
    super.key,
    this.shopId,
    this.reservationDateTime,
  });

  final String? shopId;
  final DateTime? reservationDateTime;

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}年${month}月${day}日 $hour:$minute';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync =
        shopId == null ? null : ref.watch(webPublishedShopProvider(shopId!));

    return WebPageShell(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: WebCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: webBlack,
                ),
                const SizedBox(height: 20),
                const Text(
                  '予約を受け付けました',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                const Text(
                  '店舗からのご連絡をお待ちください',
                  style: TextStyle(color: webMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (shopAsync != null)
                  shopAsync.when(
                    data: (shop) => _CompleteRow(
                      label: '店舗名',
                      value: shop?.shopName ?? '-',
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) =>
                        const _CompleteRow(label: '店舗名', value: '-'),
                  ),
                _CompleteRow(
                  label: '予約日時',
                  value: reservationDateTime == null
                      ? '-'
                      : _formatDateTime(reservationDateTime!),
                ),
                const SizedBox(height: 24),
                WebPrimaryButton(
                  label: 'トップへ戻る',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteRow extends StatelessWidget {
  const _CompleteRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: webMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
