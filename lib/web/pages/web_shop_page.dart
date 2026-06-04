import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
                sliver: SliverList.list(
                  children: [
                    const Text(
                      'Private Salon',
                      style: TextStyle(
                        color: webGold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      shop.shopName,
                      style: const TextStyle(
                        color: webDarkBrown,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _InfoCard(
                      icon: Icons.auto_awesome,
                      title: '店舗紹介',
                      value: shop.description.isEmpty
                          ? 'サロンからの紹介文は準備中です。'
                          : shop.description,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      icon: Icons.map_outlined,
                      title: '住所',
                      value: shop.address.isEmpty ? '住所は未設定です。' : shop.address,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      icon: Icons.access_time_filled_outlined,
                      title: '営業時間',
                      value: shop.businessHours.isEmpty
                          ? '営業時間は未設定です。'
                          : shop.businessHours,
                    ),
                    const SizedBox(height: 14),
                    _PhoneCard(phone: shop.phone),
                    const SizedBox(height: 30),
                    const _SectionTitle(label: 'Menu', subLabel: 'メニュー'),
                    const SizedBox(height: 14),
                    ref.watch(webMenusProvider(shop.shopId)).when(
                          data: (menus) => _MenuList(menus: menus),
                          loading: () => const WebCard(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) {
                            debugPrint('MENU ERROR => $error');
                            return const WebCard(
                              child: Text('メニューの読み込みに失敗しました。'),
                            );
                          },
                        ),
                    const SizedBox(height: 30),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: webBrown.withOpacity(0.20),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: WebPrimaryButton(
                        label: 'このサロンを予約する',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          WebRoutePaths.booking(shop.shopName),
                        ),
                      ),
                    ),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: webBrown.withOpacity(0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: imageUrl.isEmpty
          ? const _HeroPlaceholder()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, ___) {
                debugPrint('IMAGE ERROR => $error');
                return const _HeroPlaceholder();
              },
            ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

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
        child: Icon(Icons.spa, size: 86, color: Colors.white),
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.subLabel});

  final String label;
  final String subLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: webDarkBrown,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subLabel,
          style: const TextStyle(
            color: webGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final displayPhone = phone.isEmpty ? '電話番号は未設定です。' : phone;
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final canCall = normalizedPhone.isNotEmpty;

    return InkWell(
      onTap: canCall ? () => launchUrl(Uri(scheme: 'tel', path: normalizedPhone)) : null,
      borderRadius: BorderRadius.circular(28),
      child: WebCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: webGold.withOpacity(0.20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.call_outlined, color: webBrown, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '電話番号',
                    style: TextStyle(
                      color: webMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayPhone,
                    style: const TextStyle(
                      color: webDarkBrown,
                      fontSize: 16,
                      height: 1.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (canCall) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'タップして電話をかける',
                      style: TextStyle(color: webGold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            if (canCall) const Icon(Icons.chevron_right, color: webMuted),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return WebCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: webBeige.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: webBrown, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: webMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: webDarkBrown,
                    fontSize: 16,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.only(bottom: 16),
          child: WebCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        menu.name,
                        style: const TextStyle(
                          color: webDarkBrown,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: webGold.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '¥${_formatNumber(menu.price)}',
                        style: const TextStyle(
                          color: webBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: webGold),
                    const SizedBox(width: 8),
                    Text(
                      '${menu.duration}分',
                      style: const TextStyle(
                        color: webMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (menu.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
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

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
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
