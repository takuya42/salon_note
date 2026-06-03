import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_shop.dart';
import '../providers/web_home_provider.dart';
import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

class WebHomePage extends ConsumerWidget {
  const WebHomePage({super.key});

  void _openShop(BuildContext context, String shopName) {
    Navigator.pushNamed(
      context,
      WebRoutePaths.shop(shopName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(webHomeShopsProvider);

    return WebPageShell(
      maxWidth: 560,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SalonNote Web予約',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: webBlack,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '登録済み店舗一覧',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: webMuted,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            shopsAsync.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return const WebCard(
                    child: Text(
                      '登録済み店舗がありません。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: webMuted,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  );
                }

                return Column(
                  children: shops
                      .map(
                        (shop) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ShopCard(
                            shop: shop,
                            onOpen: () => _openShop(context, shop.shopName),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const WebCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: webBlack),
                  ),
                ),
              ),
              error: (error, _) => WebCard(
                child: Column(
                  children: [
                    const Text(
                      '店舗一覧を取得できませんでした。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: webBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: webMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.shop,
    required this.onOpen,
  });

  final WebShop shop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.shopName.isEmpty ? '店舗名未設定' : shop.shopName,
            style: const TextStyle(
              color: webBlack,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _ShopInfo(
            label: '店舗紹介',
            value:
                shop.description.isEmpty ? '紹介文は未設定です。' : shop.description,
          ),
          const SizedBox(height: 12),
          _ShopInfo(
            label: '営業時間',
            value: shop.businessHours.isEmpty
                ? '営業時間は未設定です。'
                : shop.businessHours,
          ),
          const SizedBox(height: 20),
          WebPrimaryButton(
            label: '店舗ページを見る',
            onPressed: shop.shopName.isEmpty ? null : onOpen,
          ),
        ],
      ),
    );
  }
}

class _ShopInfo extends StatelessWidget {
  const _ShopInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: webMuted,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: webBlack,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
