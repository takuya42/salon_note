import 'package:flutter/material.dart';

typedef SaveSale = Future<void> Function({
  required double price,
  required String menu,
  required DateTime date,
});

/// Owns the complete lifecycle of the sales form and its text controllers.
///
/// Keeping this widget separate from [SalesTab] lets the tab rebuild for
/// StreamProvider loading, data, empty, and error states without replacing or
/// manually disposing controllers that belong to an open editor route.
class SalesEditorSheet extends StatefulWidget {
  const SalesEditorSheet({
    required this.initialDate,
    required this.onSave,
    this.initialPrice,
    this.initialMenu = '',
    super.key,
  });

  final DateTime initialDate;
  final double? initialPrice;
  final String initialMenu;
  final SaveSale onSave;

  @override
  State<SalesEditorSheet> createState() => _SalesEditorSheetState();
}

class _SalesEditorSheetState extends State<SalesEditorSheet> {
  late final TextEditingController _priceController;
  late final TextEditingController _menuController;
  late DateTime _selectedDate;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _priceController = TextEditingController(
      text: widget.initialPrice?.toString() ?? '',
    );
    _menuController = TextEditingController(text: widget.initialMenu);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    // Capture primitive values before the async gap. The callback never keeps
    // a controller alive or reads one after this editor has been disposed.
    final price = double.tryParse(_priceController.text);
    final menu = _menuController.text.trim();
    final date = _selectedDate;
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい金額を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(price: price, menu: menu, date: date);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '売上入力',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: const Text('日付'),
            subtitle: Text(
              '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: _isSaving ? null : _selectDate,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '金額',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _menuController,
            enabled: !_isSaving,
            decoration: const InputDecoration(
              labelText: 'メニュー',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }
}
