import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../web/web_route_paths.dart';
import '../services/web_setting_service.dart';

const _beige = Color(0xFFE4D2C3);
const _lightBeige = Color(0xFFF8F2EC);
const _creamWhite = Color(0xFFFFFCF8);
const _darkBrown = Color(0xFF5A463A);
const _mutedBrown = Color(0xFF8A7468);
const _backgroundColor = Color(0xFFF6EFE8);

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
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _shopId;
  String _businessHours = '';
  bool _isWebPublished = false;
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
    _addressController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
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
      _addressController.text = setting.address;
      _phoneController.text = setting.phone;
      _imageUrlController.text = setting.imageUrl;
      setState(() {
        _businessHours = setting.businessHours;
        _isWebPublished = setting.isWebPublished;
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
          address: _addressController.text,
          phone: _phoneController.text,
          imageUrl: _imageUrlController.text,
          businessHours: _businessHours,
          isWebPublished: _isWebPublished,
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
        centerTitle: true,
        title: const Text(
          'Web公開設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        foregroundColor: _darkBrown,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                const _HeaderCard(),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  _ErrorCard(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],
                _SettingCard(
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _darkBrown,
                    title: const Text(
                      'Webページを公開',
                      style: TextStyle(
                        color: _darkBrown,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text('オフにすると公開ページを非公開にします'),
                    value: _isWebPublished,
                    onChanged: (value) {
                      setState(() => _isWebPublished = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _SettingCard(
                  child: Column(
                    children: [
                      _TextField(
                        controller: _shopNameController,
                        label: '店舗名',
                        icon: Icons.storefront,
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        controller: _descriptionController,
                        label: '店舗紹介',
                        icon: Icons.notes,
                        minLines: 3,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        controller: _addressController,
                        label: '住所',
                        icon: Icons.location_on,
                        keyboardType: TextInputType.multiline,
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      _TextField(
                        controller: _phoneController,
                        label: '電話番号',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _BusinessHoursPanel(businessHours: _businessHours),
                      const SizedBox(height: 16),
                      _TextField(
                        controller: _imageUrlController,
                        label: 'メイン画像URL',
                        icon: Icons.image,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_shopId != null)
                  _SettingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '公開URL',
                          style: TextStyle(
                            color: _darkBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          WebRoutePaths.canonicalShopUri(_shopId!).toString(),
                          style: const TextStyle(color: _mutedBrown),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _copyUrl,
                            icon: const Icon(Icons.copy),
                            label: const Text('公開URLをコピー'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _beige,
                              foregroundColor: _darkBrown,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkBrown,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: _darkBrown.withAlpha(61),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '設定を保存',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _creamWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkBrown.withAlpha(41),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _lightBeige,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.language, color: _darkBrown, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Web予約ページ',
                  style: TextStyle(
                    color: _darkBrown,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '公開ページを管理できます',
                  style: TextStyle(color: _mutedBrown, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessHoursPanel extends StatelessWidget {
  const _BusinessHoursPanel({required this.businessHours});

  final String businessHours;

  @override
  Widget build(BuildContext context) {
    final displayText = businessHours.trim().isEmpty
        ? '営業設定で営業時間と定休日を設定すると自動表示されます。'
        : businessHours;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _lightBeige,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _beige.withAlpha(204)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, color: _darkBrown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '営業時間表示',
                  style: TextStyle(
                    color: _darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayText,
                  style: const TextStyle(
                    color: _mutedBrown,
                    height: 1.6,
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

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _creamWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkBrown.withAlpha(36),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Colors.redAccent)),
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
      style: const TextStyle(color: _darkBrown),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _mutedBrown),
        labelText: label,
        labelStyle: const TextStyle(color: _mutedBrown),
        filled: true,
        fillColor: _lightBeige,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _beige.withAlpha(204)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _darkBrown, width: 1.4),
        ),
      ),
    );
  }
}
