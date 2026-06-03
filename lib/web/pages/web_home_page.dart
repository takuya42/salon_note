import 'package:flutter/material.dart';

import '../web_route_paths.dart';
import '../widgets/web_design_widgets.dart';

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  final _shopIdController = TextEditingController();

  @override
  void dispose() {
    _shopIdController.dispose();
    super.dispose();
  }

  void _openShop() {
    final shopId = _shopIdController.text.trim();

    if (shopId.isEmpty) {
      return;
    }

    Navigator.pushNamed(
      context,
      WebRoutePaths.shop(shopId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebPageShell(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 12),
                const Text(
                  'サロン向けの予約ページです。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: webMuted,
                    fontSize: 15,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 32),
                WebCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '店舗IDを入力',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: webBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _shopIdController,
                        decoration: InputDecoration(
                          hintText: '店舗IDを入力',
                          filled: true,
                          fillColor: webLightBeige,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _openShop(),
                      ),
                      const SizedBox(height: 20),
                      WebPrimaryButton(
                        label: '予約ページを開く',
                        onPressed: _openShop,
                      ),
                    ],
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