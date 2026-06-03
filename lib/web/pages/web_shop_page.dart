import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/web_menu.dart';
import '../models/web_shop.dart';
import '../providers/web_shop_provider.dart';
import '../web_development_mode.dart';
import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

class WebShopPage extends ConsumerWidget {
  const WebShopPage({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(webShopProvider(shopId));
    final menusAsync = ref.watch(webMenusProvider(shopId));

    return WebPageShell(
      child: shopAsync.when(
        data: (shop) {
          final displayShop = shop ?? _dummyShop(shopId);
          if (displayShop == null) {
            return _NotFoundContent(shopId: shopId);
          }

          final useDummyMenus = shop == null && isDevelopmentMode;
          final isPublic = displayShop.webEnabled || useDummyMenus;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroImage(imageUrl: displayShop.displayImageUrl),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                sliver: SliverList.list(
                  children: [
                    Text(
                      displayShop.shopName,
                      style: const TextStyle(
                        color: webBlack,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (displayShop.displayDescription.isNotEmpty)
                      Text(
                        displayShop.displayDescription,
                        style: const TextStyle(
                          color: webMuted,
                          height: 1.8,
                          fontSize: 15,
                        ),
                      ),
                    const SizedBox(height: 18),
                    _SocialButtons(shop: displayShop),
                    const SizedBox(height: 18),
                    if (!isPublic) ...[
                      const WebCard(
                        child: Text(
                          '現在Web予約は公開されていません',
                          style: TextStyle(
                            color: webBlack,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    WebCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Information',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (displayShop.businessHours.isNotEmpty)
                            _InfoRow(
                              label: '営業時間',
                              value: displayShop.businessHours,
                            ),
                          if (displayShop.phone.isNotEmpty)
                            _InfoRow(label: '電話番号', value: displayShop.phone),
                          _InfoRow(label: '店舗ID', value: displayShop.shopId),
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
                    if (useDummyMenus)
                      _MenuList(menus: _dummyMenus(shopId))
                    else
                      menusAsync.when(
                        data: (menus) => _MenuList(menus: menus),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const Text('メニューの読み込みに失敗しました。'),
                      ),
                    if (isPublic) ...[
                      const SizedBox(height: 24),
                      WebPrimaryButton(
                        label: useDummyMenus ? '予約ページへ進む' : 'このサロンを予約する',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          WebRoutePaths.booking(shopId),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('店舗情報の読み込みに失敗しました。')),
      ),
    );
  }

  WebShop? _dummyShop(String shopId) {
    if (!isDevelopmentMode) return null;
    return WebShop(
      shopId: shopId,
      shopName: 'テスト店舗',
      description: '',
      phone: '090-1234-5678',
      imageUrl: '',
      businessHours: '10:00〜19:00',
      ownerId: 'development-owner',
      ownerEmail: 'development@example.com',
      planType: 'free',
      webEnabled: true,
      webDescription: '開発用ダミー店舗です。Web予約ページの表示確認に利用できます。',
      webImageUrl: '',
      instagramUrl: '',
      lineUrl: '',
      createdAt: null,
    );
  }

  List<WebMenu> _dummyMenus(String shopId) {
    return [
      WebMenu(
        menuId: 'development-cut',
        shopId: shopId,
        name: 'カット',
        price: 0,
        duration: 60,
        description: '開発用ダミーメニュー',
        createdAt: null,
      ),
    ];
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

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.shop});

  final WebShop shop;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    if (shop.instagramUrl.isNotEmpty) {
      buttons.add(
        _SocialButton(
          label: 'Instagram',
          icon: Icons.camera_alt_outlined,
          url: shop.instagramUrl,
        ),
      );
    }
    if (shop.lineUrl.isNotEmpty) {
      buttons.add(
        _SocialButton(
          label: 'LINE',
          icon: Icons.chat_bubble_outline,
          url: shop.lineUrl,
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: buttons
          .map(
            (button) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: button,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: webBlack,
        side: const BorderSide(color: webBeige),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
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
          Expanded(child: Text(value, style: const TextStyle(color: webBlack))),
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
                    if (menu.price > 0)
                      Text(
                        '¥${menu.price}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${menu.duration}分', style: const TextStyle(color: webMuted)),
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
  const _NotFoundContent({required this.shopId});

  final String shopId;

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
              Text('店舗「$shopId」が見つかりません'),
              const SizedBox(height: 16),
              WebPrimaryButton(
                label: 'トップへ戻る',
                onPressed: () =>
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
