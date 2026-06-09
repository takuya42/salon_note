import 'package:flutter/material.dart';

const _beige = Color(0xFFD8C2B9);
const _darkBrown = Color(0xFF5B463C);
const _surface = Color(0xFFFFFBF8);

typedef SaveSale = Future<void> Function({
  required double price,
  required String menu,
  required DateTime date,
});

class SalesEditorSheet extends StatefulWidget {
  const SalesEditorSheet({
    required this.initialDate,
    required this.onSave,
    this.initialPrice,
    this.initialMenu = '',
    this.title = '売上入力',
    this.onDelete,
    super.key,
  });

  final DateTime initialDate;
  final double? initialPrice;
  final String initialMenu;
  final String title;
  final SaveSale onSave;
  final Future<void> Function()? onDelete;

  @override
  State<SalesEditorSheet> createState() => _SalesEditorSheetState();
}

class _SalesEditorSheetState extends State<SalesEditorSheet> {
  late final TextEditingController _priceController;
  late final TextEditingController _menuController;
  late DateTime _selectedDate;
  var _isSaving = false;
  var _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _priceController = TextEditingController(
      text: widget.initialPrice == null
          ? ''
          : widget.initialPrice!.toStringAsFixed(
              widget.initialPrice! % 1 == 0 ? 0 : 2,
            ),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _darkBrown),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_isBusy) return;
    final price = double.tryParse(_priceController.text.replaceAll(',', ''));
    final menu = _menuController.text.trim();
    final date = _selectedDate;
    if (price == null || price <= 0) {
      _showMessage('正しい金額を入力してください');
      return;
    }
    if (menu.isEmpty) {
      _showMessage('メニュー名を入力してください');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(price: price, menu: menu, date: date);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('保存に失敗しました');
    }
  }

  Future<void> _confirmDelete() async {
    if (_isBusy || widget.onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('売上を削除しますか？'),
        content: const Text('削除した売上は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      _showMessage('削除に失敗しました');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _beige,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.title,
              style: const TextStyle(
                color: _darkBrown,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.onDelete == null ? '施術内容と売上を記録します' : '登録済みの売上内容を編集できます',
              style: TextStyle(color: _darkBrown.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            _EditorField(
              label: '日付',
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: Text(
                  '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                  style: const TextStyle(
                    color: _darkBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.calendar_month_rounded, color: _darkBrown),
                onTap: _isBusy ? null : _selectDate,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              enabled: !_isBusy,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('金額', '例：12000', prefixText: '¥ '),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _menuController,
              enabled: !_isBusy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: _decoration('メニュー名', '例：カット＋カラー'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _darkBrown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isBusy ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('保存', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            if (widget.onDelete != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isBusy ? null : _confirmDelete,
                  icon: _isDeleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: const Text('この売上を削除'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    String hint, {
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _beige.withOpacity(0.55)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _beige.withOpacity(0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkBrown, width: 1.4),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _surface,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _beige.withOpacity(0.55)),
        ),
      ),
      child: child,
    );
  }
}
