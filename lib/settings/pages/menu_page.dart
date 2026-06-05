import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/web_setting_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, WebSettingService? service}) : _service = service;

  final WebSettingService? _service;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final WebSettingService _service =
      widget._service ?? WebSettingService();

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> addMenu() async {
    final shopId = await _service.fetchCurrentShopId();

    if (shopId == null) return;
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      return;
    }

    await _service.addMenu(
      shopId: shopId,
      name: nameController.text,
      price: int.tryParse(priceController.text.trim()) ?? 0,
      duration: int.tryParse(durationController.text.trim()) ?? 0,
      description: descriptionController.text,
    );

    nameController.clear();
    priceController.clear();
    durationController.clear();
    descriptionController.clear();
  }

  Future<void> deleteMenu(String id) async {
    await _service.deleteMenu(id);
  }

  Stream<List<WebSettingMenuData>> menuStream() {
    return _service.watchCurrentShopMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー管理'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'メニュー名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '料金（円）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '施術時間（分）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '説明',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: addMenu,
                  child: const Text('追加'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<WebSettingMenuData>>(
              stream: menuStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('MENU LOAD ERROR => ${snapshot.error}');

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        'メニューの読み込みに失敗しました。\n例外: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final menus = snapshot.data!;

                if (menus.isEmpty) {
                  return const Center(child: Text('メニューがありません'));
                }

                return ListView.builder(
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    final menu = menus[index];

                    return ListTile(
                      title: Text(menu.name),
                      subtitle: Text('¥${menu.price} / ${menu.duration}分'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteMenu(menu.menuId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
