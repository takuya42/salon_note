import 'package:flutter/material.dart';

import '../services/web_setting_service.dart';

const primaryColor = Color(0xFFD8C2B9);
const darkBrown = Color(0xFF5C4A43);
const backgroundColor = Color(0xFFF7F3F0);

class WebSettingPage extends StatefulWidget {
  const WebSettingPage({super.key});

  @override
  State<WebSettingPage> createState() => _WebSettingPageState();
}

class _WebSettingPageState extends State<WebSettingPage> {
  final _service = WebSettingService();
  final _webImageUrlController = TextEditingController();
  final _webDescriptionController = TextEditingController();
  final _instagramUrlController = TextEditingController();
  final _lineUrlController = TextEditingController();

  String? _shopId;
  bool _webEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _webImageUrlController.dispose();
    _webDescriptionController.dispose();
    _instagramUrlController.dispose();
    _lineUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.fetchCurrentShopWebSettings();
    if (!mounted) return;

    if (settings == null) {
      setState(() => _isLoading = false);
      return;
    }

    _shopId = settings.shopId;
    _webImageUrlController.text = settings.webImageUrl;
    _webDescriptionController.text = settings.webDescription;
    _instagramUrlController.text = settings.instagramUrl;
    _lineUrlController.text = settings.lineUrl;
    _webEnabled = settings.webEnabled;

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final shopId = _shopId;
    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('店舗情報が見つかりません')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.saveWebSettings(
        WebSettingData(
          shopId: shopId,
          webImageUrl: _webImageUrlController.text.trim(),
          webDescription: _webDescriptionController.text.trim(),
          instagramUrl: _instagramUrlController.text.trim(),
          lineUrl: _lineUrlController.text.trim(),
          webEnabled: _webEnabled,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web予約設定を保存しました')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Web予約設定'),
        backgroundColor: primaryColor,
        foregroundColor: darkBrown,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language, color: darkBrown),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Web予約公開',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '店舗ページを公開してお客様から予約を受け付けます',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeColor: darkBrown,
                  value: _webEnabled,
                  onChanged: (value) => setState(() => _webEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '店舗ページ内容',
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _textField(
                  controller: _webImageUrlController,
                  label: '店舗画像URL',
                  hint: 'https://example.com/salon.jpg',
                  icon: Icons.image_outlined,
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _webDescriptionController,
                  label: '店舗紹介文',
                  hint: 'サロンの雰囲気やこだわりを入力してください',
                  icon: Icons.notes_outlined,
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _instagramUrlController,
                  label: 'Instagram URL',
                  hint: 'https://www.instagram.com/your_salon',
                  icon: Icons.camera_alt_outlined,
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: _lineUrlController,
                  label: 'LINE URL',
                  hint: 'https://lin.ee/xxxx',
                  icon: Icons.chat_bubble_outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '保存する',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.url,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: darkBrown),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
