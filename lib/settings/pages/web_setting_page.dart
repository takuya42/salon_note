import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final _imagePicker = ImagePicker();

  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<_MenuFormEntry> _menuEntries = [];

  String? _shopId;
  String _imageUrl = '';
  String _businessHours = '';
  bool _isWebPublished = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
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
    for (final entry in _menuEntries) {
      entry.dispose();
    }
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

      final menus = await _service.fetchMenus(setting.shopId);
      if (!mounted) return;

      _shopId = setting.shopId;
      _shopNameController.text = setting.shopName;
      _descriptionController.text = setting.description;
      _addressController.text = setting.address;
      _phoneController.text = setting.phone;
      _replaceMenuEntries(menus);
      setState(() {
        _imageUrl = setting.imageUrl;
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
          imageUrl: _imageUrl,
          businessHours: _businessHours,
          isWebPublished: _isWebPublished,
        ),
      );
      await _service.saveMenus(
        shopId: shopId,
        menus: _menuEntries.map((entry) => entry.toMenuData(shopId)).toList(),
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

  Future<void> _pickAndUploadImage() async {
    final shopId = _shopId;
    if (shopId == null || _isUploadingImage) return;

    debugPrint('IMAGE PICK START');

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );

    debugPrint('IMAGE PICK RESULT => ${pickedImage?.path}');

    if (pickedImage == null) {
      debugPrint('IMAGE PICK CANCELLED');
      return;
    }

    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
    });

    try {
      debugPrint('IMAGE UPLOAD START');

      try {
        final downloadUrl = await _service.uploadShopCoverImage(
          shopId: shopId,
          image: pickedImage,
        );

        debugPrint('IMAGE UPLOAD SUCCESS => $downloadUrl');

        if (!mounted) return;
        setState(() => _imageUrl = downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('店舗画像をアップロードしました')),
        );
      } catch (error, stackTrace) {
        debugPrint('IMAGE UPLOAD ERROR => $error');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '店舗画像のアップロードに失敗しました。');
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
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

  void _replaceMenuEntries(List<WebSettingMenuData> menus) {
    for (final entry in _menuEntries) {
      entry.dispose();
    }
    _menuEntries
      ..clear()
      ..addAll(menus.map(_MenuFormEntry.fromMenu));
  }

  void _addMenu() {
    setState(() => _menuEntries.add(_MenuFormEntry.empty()));
  }

  void _removeMenu(int index) {
    final entry = _menuEntries.removeAt(index);
    entry.dispose();
    setState(() {});
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
                      _ImageUploadPanel(
                        imageUrl: _imageUrl,
                        isUploading: _isUploadingImage,
                        onPickImage: _pickAndUploadImage,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingCard(
                  child: _MenuSettingSection(
                    entries: _menuEntries,
                    onAdd: _addMenu,
                    onRemove: _removeMenu,
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

class _MenuFormEntry {
  _MenuFormEntry({
    required this.menuId,
    required this.createdAt,
    required String name,
    required int price,
    required int duration,
    required String description,
  })  : nameController = TextEditingController(text: name),
        priceController = TextEditingController(
          text: price == 0 ? '' : price.toString(),
        ),
        durationController = TextEditingController(
          text: duration == 0 ? '' : duration.toString(),
        ),
        descriptionController = TextEditingController(text: description);

  factory _MenuFormEntry.empty() {
    return _MenuFormEntry(
      menuId: '',
      createdAt: null,
      name: '',
      price: 0,
      duration: 0,
      description: '',
    );
  }

  factory _MenuFormEntry.fromMenu(WebSettingMenuData menu) {
    return _MenuFormEntry(
      menuId: menu.menuId,
      createdAt: menu.createdAt,
      name: menu.name,
      price: menu.price,
      duration: menu.duration,
      description: menu.description,
    );
  }

  final String menuId;
  final DateTime? createdAt;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController durationController;
  final TextEditingController descriptionController;

  WebSettingMenuData toMenuData(String shopId) {
    return WebSettingMenuData(
      menuId: menuId,
      shopId: shopId,
      name: nameController.text,
      price: int.tryParse(priceController.text.trim()) ?? 0,
      duration: int.tryParse(durationController.text.trim()) ?? 0,
      description: descriptionController.text,
      createdAt: createdAt,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
    descriptionController.dispose();
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
                  '店舗情報・メニュー・画像を管理できます',
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

class _ImageUploadPanel extends StatelessWidget {
  const _ImageUploadPanel({
    required this.imageUrl,
    required this.isUploading,
    required this.onPickImage,
  });

  final String imageUrl;
  final bool isUploading;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _lightBeige,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _beige.withAlpha(204)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '店舗画像',
            style: TextStyle(
              color: _darkBrown,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isUploading ? null : onPickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isEmpty)
                      Container(
                        color: _beige.withAlpha(120),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 54,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'タップして画像を選択',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: _beige.withAlpha(120),
                          child: const Icon(
                            Icons.broken_image,
                            color: _mutedBrown,
                          ),
                        ),
                      ),
                    if (imageUrl.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    if (isUploading)
                      Container(
                        color: Colors.black.withAlpha(77),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : onPickImage,
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(isUploading ? 'アップロード中...' : '画像選択'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkBrown,
                side: const BorderSide(color: _beige),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '新しい画像を選択すると shop_cover.jpg として上書き保存されます。',
            style: TextStyle(color: _mutedBrown, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MenuSettingSection extends StatelessWidget {
  const _MenuSettingSection({
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_MenuFormEntry> entries;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'メニュー管理',
                    style: TextStyle(
                      color: _darkBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '公開ページに表示するメニューを追加できます',
                    style: TextStyle(color: _mutedBrown, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              color: _darkBrown,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _lightBeige,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '「＋」ボタンからメニューを追加してください。',
              style: TextStyle(color: _mutedBrown),
            ),
          )
        else
          ...entries.indexed.map((item) {
            final index = item.$1;
            final entry = item.$2;
            return Padding(
              padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 16),
              child: _MenuEditorCard(
                index: index,
                entry: entry,
                onRemove: () => onRemove(index),
              ),
            );
          }),
      ],
    );
  }
}

class _MenuEditorCard extends StatelessWidget {
  const _MenuEditorCard({
    required this.index,
    required this.entry,
    required this.onRemove,
  });

  final int index;
  final _MenuFormEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightBeige,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _beige.withAlpha(204)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'メニュー ${index + 1}',
                  style: const TextStyle(
                    color: _darkBrown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                color: _mutedBrown,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TextField(
            controller: entry.nameController,
            label: 'メニュー名',
            icon: Icons.spa,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TextField(
                  controller: entry.priceController,
                  label: '料金（円）',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TextField(
                  controller: entry.durationController,
                  label: '施術時間（分）',
                  icon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TextField(
            controller: entry.descriptionController,
            label: '説明',
            icon: Icons.description_outlined,
            minLines: 2,
            maxLines: 4,
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
        fillColor: _creamWhite,
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
