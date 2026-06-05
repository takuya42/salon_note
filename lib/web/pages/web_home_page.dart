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
      maxWidth: 620,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SalonNote',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: webGold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Web予約',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: webDarkBrown,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '登録済み店舗一覧',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: webMuted,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
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
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ShopCard(
                            shop: shop,
                            onOpen: shop.shopName.isEmpty
                                ? null
                                : () => _openShop(context, shop.shopName),
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
                    child: CircularProgressIndicator(color: webDarkBrown),
                  ),
                ),
              ),
              error: (error, _) {
                return WebCard(
                  child: Column(
                    children: [
                      const Text(
                        '店舗一覧を取得できませんでした。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: webDarkBrown,
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
                );
              },
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
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(30),
        child: WebCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShopImage(imageUrl: shop.imageUrl),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.shopName.isEmpty ? '店舗名未設定' : shop.shopName,
                      style: const TextStyle(
                        color: webDarkBrown,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ShopInfo(
                      icon: Icons.location_on_outlined,
                      label: '住所',
                      value: shop.address.isEmpty ? '住所は未設定です。' : shop.address,
                    ),
                    const SizedBox(height: 12),
                    _ShopInfo(
                      icon: Icons.schedule,
                      label: '営業時間',
                      value: shop.businessHours.isEmpty
                          ? '営業時間は未設定です。'
                          : shop.businessHours,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        Text(
                          '店舗ページを見る',
                          style: TextStyle(
                            color: webBrown,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: webBrown, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopImage extends StatelessWidget {
  const _ShopImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    const placeholder = _ShopImagePlaceholder();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}

class _ShopImagePlaceholder extends StatelessWidget {
  const _ShopImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [webBeige, webCream],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.spa, color: Colors.white, size: 60),
      ),
    );
  }
}

class _ShopInfo extends StatelessWidget {
  const _ShopInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: webGold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: webMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: webDarkBrown,
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
