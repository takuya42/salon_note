import 'package:flutter/material.dart';

import '../widgets/web_design_widgets.dart';

class WebNotFoundPage extends StatelessWidget {
  const WebNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebPageShell(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: WebCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: webMuted),
                const SizedBox(height: 16),
                const Text(
                  'ページが見つかりません',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                WebPrimaryButton(
                  label: 'トップへ戻る',
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
