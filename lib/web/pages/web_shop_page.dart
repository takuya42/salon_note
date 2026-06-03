import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/web_menu.dart';
import '../providers/web_shop_provider.dart';
import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

class WebShopPage extends ConsumerWidget {
  const WebShopPage({super.key, required this.shopName});

  final String shopName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(webShopProvider(shopName));

    return WebPageShell(
      child: shopAsync.when(
        data: (shop) {
          if (shop == null || !shop.isWebPublished) {
            return const _NotFoundContent();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HeroImage(imageUrl: shop.imageUrl)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                sliver: SliverList.list(
                  children: [
                    Text(
                      shop.shopName,
                      style: const TextStyle(
                        color: webBlack,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (shop.description.isNotEmpty)
                      Text(
                        shop.description,
                        style: const TextStyle(
                          color: webMuted,
                          height: 1.8,
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 20),
                    WebCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Information',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (shop.businessHours.isNotEmpty)
                            _InfoRow(label: '営業時間', value: shop.businessHours),
                          if (shop.phone.isNotEmpty)
                            _InfoRow(label: '電話番号', value: shop.phone),
                          _InfoRow(label: '店舗ID', value: shop.shopId),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Menu',
                      style: TextStyle(
                        color: webBlack,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ref.watch(webMenusProvider(shop.shopId)).when(
                      data: (menus) => _MenuList(menus: menus),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('メニューの読み込みに失敗しました。'),
                    ),
                    const SizedBox(height: 24),
                    if (shop.isWebBookingEnabled)
                      WebPrimaryButton(
                        label: 'このサロンを予約する',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          WebRoutePaths.booking(shop.shopName),
                        ),
                      )
                    else
                      const WebCard(child: Text('現在Web予約の受付を停止しています。')),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('店舗情報の読み込みに失敗しました。'),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: imageUrl.isEmpty
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [webBeige, webLightBeige],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.spa, size: 72, color: Colors.white),
              ),
            )
          : Image.network(imageUrl, fit: BoxFit.cover),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label, style: const TextStyle(color: webMuted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: webBlack)),
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.menus});

  final List<WebMenu> menus;

  @override
  Widget build(BuildContext context) {
    if (menus.isEmpty) {
      return const WebCard(child: Text('現在公開中のメニューはありません。'));
    }

    return Column(
      children: menus.map((menu) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WebCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        menu.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '¥${menu.price}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${menu.duration}分',
                  style: const TextStyle(color: webMuted),
                ),
                if (menu.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    menu.description,
                    style: const TextStyle(color: webMuted, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NotFoundContent extends StatelessWidget {
  const _NotFoundContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: WebCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: webMuted),
              const SizedBox(height: 16),
              const Text(
                'サロンが見つかりません\n店舗名をご確認ください',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
    );
  }
}
