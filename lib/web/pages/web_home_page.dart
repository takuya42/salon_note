import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/web_shop.dart';
import '../providers/web_home_provider.dart';
import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) {
    return;
  }
  await launchUrl(uri, webOnlyWindowName: '_blank');
}

Future<void> _openMapForAddress(String address) async {
  final normalizedAddress = address.trim();
  if (normalizedAddress.isEmpty) {
    return;
  }
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': normalizedAddress,
  });
  await launchUrl(uri, webOnlyWindowName: '_blank');
}

class WebHomePage extends ConsumerStatefulWidget {
  const WebHomePage({super.key});

  @override
  ConsumerState<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends ConsumerState<WebHomePage> {
  final _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openShop(BuildContext context, String shopId) {
    Navigator.pushNamed(
      context,
      WebRoutePaths.shop(shopId),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 24),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchKeyword = value);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '店舗名で検索',
                hintStyle: const TextStyle(color: webMuted),
                prefixIcon: const Icon(Icons.search, color: webMuted),
                suffixIcon: _searchKeyword.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '検索をクリア',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchKeyword = '');
                        },
                        icon: const Icon(Icons.close, color: webMuted),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: webBeige),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: webGold, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            shopsAsync.when(
              data: (shops) {
                final keyword = _searchKeyword.trim().toLowerCase();
                final filteredShops = keyword.isEmpty
                    ? shops
                    : shops
                        .where(
                          (shop) =>
                              shop.shopName.toLowerCase().contains(keyword),
                        )
                        .toList();

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

                if (filteredShops.isEmpty) {
                  return const WebCard(
                    child: Text(
                      '検索条件に一致する店舗がありません。',
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
                  children: filteredShops
                      .map(
                        (shop) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _ShopCard(
                            shop: shop,
                            onOpen: shop.shopId.isEmpty
                                ? null
                                : () => _openShop(context, shop.shopId),
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
                      onTap: shop.address.trim().isEmpty
                          ? null
                          : () => _openMapForAddress(shop.address),
                      actionLabel: 'Googleマップで開く',
                    ),
                    const SizedBox(height: 12),
                    _ShopInfo(
                      icon: Icons.schedule,
                      label: '営業時間',
                      value: shop.businessHours.isEmpty
                          ? '営業時間は未設定です。'
                          : shop.businessHours,
                    ),
                    _ShopLinks(shop: shop),
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
    this.onTap,
    this.actionLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final content = Row(
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
              if (onTap != null && actionLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: webGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }
}

class _ShopLinks extends StatelessWidget {
  const _ShopLinks({required this.shop});

  final WebShop shop;

  @override
  Widget build(BuildContext context) {
    final links = <({String label, String url})>[
      if (shop.instagramUrl.isNotEmpty)
        (label: 'Instagram', url: shop.instagramUrl),
      if (shop.lineUrl.isNotEmpty) (label: 'LINE', url: shop.lineUrl),
      if (shop.websiteUrl.isNotEmpty) (label: 'ホームページ', url: shop.websiteUrl),
    ];

    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: links
            .map(
              (link) => ActionChip(
                label: Text(link.label),
                avatar: const Icon(Icons.open_in_new, size: 16),
                onPressed: () => _openExternalUrl(link.url),
                backgroundColor: webLightBeige,
                labelStyle: const TextStyle(
                  color: webDarkBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
