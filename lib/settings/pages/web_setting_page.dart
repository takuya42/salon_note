import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../web/web_route_paths.dart';
import '../services/web_setting_service.dart';

const _primaryColor = Color(0xFFD8C2B9);
const _darkBrown = Color(0xFF5C4A43);
const _backgroundColor = Color(0xFFF7F3F0);

class WebSettingPage extends StatefulWidget {
  const WebSettingPage({super.key, WebSettingService? service})
      : _service = service;

  final WebSettingService? _service;

  @override
  State<WebSettingPage> createState() => _WebSettingPageState();
}

class _WebSettingPageState extends State<WebSettingPage> {
  late final WebSettingService _service =
      widget._service ?? WebSettingService();

  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _businessHoursController = TextEditingController();

  String? _shopId;
  bool _isWebPublished = false;
  bool _isWebBookingEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _businessHoursController.dispose();
    super.dispose();
  }

  Future<void> _loadSetting() async {
    try {
      final setting = await _service.fetchCurrentSetting();
      if (!mounted) return;

      if (setting == null) {
        setState(() {
          _errorMessage = '店舗情報が見つかりません。';
          _isLoading = false;
        });
        return;
      }

      _shopId = setting.shopId;
      _shopNameController.text = setting.shopName;
      _descriptionController.text = setting.description;
      _phoneController.text = setting.phone;
      _imageUrlController.text = setting.imageUrl;
      _businessHoursController.text = setting.businessHours;
      setState(() {
        _isWebPublished = setting.isWebPublished;
        _isWebBookingEnabled = setting.isWebBookingEnabled;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Web公開設定の読み込みに失敗しました。';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final shopId = _shopId;
    if (shopId == null) return;

    if (_shopNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '店舗名を入力してください。');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _service.save(
        WebSettingData(
          shopId: shopId,
          shopName: _shopNameController.text,
          description: _descriptionController.text,
          phone: _phoneController.text,
          imageUrl: _imageUrlController.text,
          businessHours: _businessHoursController.text,
          isWebPublished: _isWebPublished,
          isWebBookingEnabled: _isWebBookingEnabled,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web公開設定を保存しました')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Web公開設定の保存に失敗しました。');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _copyUrl() async {
    final shopId = _shopId;
    if (shopId == null) return;

    await Clipboard.setData(
      ClipboardData(text: WebRoutePaths.canonicalShopUri(shopId).toString()),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('公開URLをコピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Web公開設定'),
        backgroundColor: _primaryColor,
        foregroundColor: _darkBrown,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errorMessage != null) ...[
                  _ErrorCard(message: _errorMessage!),
                  const SizedBox(height: 12),
                ],
                _SettingCard(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: _darkBrown,
                      title: const Text('Webページを公開'),
                      subtitle: const Text('オフにすると公開ページと予約ページを非公開にします'),
                      value: _isWebPublished,
                      onChanged: (value) {
                        setState(() {
                          _isWebPublished = value;
                          if (!value) _isWebBookingEnabled = false;
                        });
                      },
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: _darkBrown,
                      title: const Text('Web予約を受け付ける'),
                      subtitle: const Text('公開ページからの予約ボタンと予約フォームを有効にします'),
                      value: _isWebBookingEnabled,
                      onChanged: _isWebPublished
                          ? (value) => setState(
                                () => _isWebBookingEnabled = value,
                              )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SettingCard(
                  children: [
                    _TextField(
                      controller: _shopNameController,
                      label: '店舗名',
                      icon: Icons.storefront,
                    ),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _descriptionController,
                      label: '店舗紹介',
                      icon: Icons.notes,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _phoneController,
                      label: '電話番号',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _businessHoursController,
                      label: '営業時間表示',
                      icon: Icons.schedule,
                    ),
                    const SizedBox(height: 12),
                    _TextField(
                      controller: _imageUrlController,
                      label: 'メイン画像URL',
                      icon: Icons.image,
                      keyboardType: TextInputType.url,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_shopId != null)
                  _SettingCard(
                    children: [
                      const Text(
                        '公開URL',
                        style: TextStyle(
                          color: _darkBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        WebRoutePaths.canonicalShopUri(_shopId!).toString(),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _copyUrl,
                        icon: const Icon(Icons.copy),
                        label: const Text('URLをコピー'),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}
