import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../repositories/customer_repository.dart';

const primaryColor = Color(0xFFD8C2B9);
const darkBrown = Color(0xFF5B463C);
const backgroundColor = Color(0xFFFAF7F4);
const _mutedBrown = Color(0xFF8E766C);
const _surface = Color(0xFFFFFDFC);

class CustomerDetailPage extends ConsumerStatefulWidget {
  const CustomerDetailPage({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController memoController;
  var _didSyncRemoteCustomer = false;
  var _isSavingProfile = false;
  var _isSavingMemo = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    nameController = TextEditingController(text: customer.name);
    emailController = TextEditingController(text: customer.email);
    phoneController = TextEditingController(text: customer.phone);
    memoController = TextEditingController(text: customer.memo);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    memoController.dispose();
    super.dispose();
  }

  void _syncControllers(Customer customer) {
    if (_didSyncRemoteCustomer) return;
    _didSyncRemoteCustomer = true;
    nameController.text = customer.name;
    emailController.text = customer.email;
    phoneController.text = customer.phone;
    memoController.text = customer.memo;
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('顧客名を入力してください');
      return;
    }
    setState(() => _isSavingProfile = true);
    try {
      await ref.read(customerProvider.notifier).updateCustomer(
            widget.customer.id,
            name: name,
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
          );
      _showMessage('基本情報を保存しました');
    } catch (_) {
      _showMessage('基本情報の保存に失敗しました');
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _saveMemo() async {
    if (_isSavingMemo) return;
    setState(() => _isSavingMemo = true);
    try {
      await ref
          .read(customerProvider.notifier)
          .updateMemo(widget.customer.id, memoController.text.trim());
      _showMessage('カルテを保存しました');
    } catch (_) {
      _showMessage('カルテの保存に失敗しました');
    } finally {
      if (mounted) setState(() => _isSavingMemo = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(customerDetailProvider(widget.customer.id));
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: darkBrown,
        elevation: 0,
        title: const Text('顧客カルテ', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: detail.when(
        loading: () => const _DetailLoadingState(),
        error: (error, _) => _DetailErrorState(
          error: error,
          onRetry: () => ref.invalidate(customerDetailProvider(widget.customer.id)),
        ),
        data: (data) {
          if (data == null) {
            return const _DetailNotFoundState();
          }
          _syncControllers(data.customer);
          return _buildDetail(data);
        },
      ),
    );
  }

  Widget _buildDetail(CustomerDetailData detail) {
    final totalSales = detail.sales.fold<double>(0, (total, document) {
      final price = document.data()['price'];
      return total + (price is num ? price.toDouble() : 0);
    });

    return RefreshIndicator(
      color: darkBrown,
      onRefresh: () async {
        ref.invalidate(customerDetailProvider(widget.customer.id));
        await ref.read(customerDetailProvider(widget.customer.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _CustomerHeader(
            name: detail.customer.name,
            visitCount: detail.sales.length,
            totalSales: totalSales,
          ),
          const SizedBox(height: 22),
          _SectionCard(
            title: '基本情報',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                _CustomerTextField(controller: nameController, label: 'お名前'),
                const SizedBox(height: 14),
                _CustomerTextField(
                  controller: phoneController,
                  label: '電話番号',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _CustomerTextField(
                  controller: emailController,
                  label: 'メールアドレス',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                _SaveButton(
                  label: '基本情報を保存',
                  isSaving: _isSavingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'カルテメモ',
            icon: Icons.edit_note_rounded,
            child: Column(
              children: [
                _CustomerTextField(
                  controller: memoController,
                  label: '施術内容・会話内容・注意事項など',
                  maxLines: 6,
                ),
                const SizedBox(height: 18),
                _SaveButton(
                  label: 'カルテを保存',
                  isSaving: _isSavingMemo,
                  onPressed: _saveMemo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '売上履歴',
                style: TextStyle(color: darkBrown, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              Text('${detail.sales.length}件', style: const TextStyle(color: _mutedBrown)),
            ],
          ),
          const SizedBox(height: 12),
          if (detail.sales.isEmpty)
            const _NoCustomerSales()
          else
            ...detail.sales.map((sale) => _CustomerSaleCard(data: sale.data())),
        ],
      ),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({
    required this.name,
    required this.visitCount,
    required this.totalSales,
  });

  final String name;
  final int visitCount;
  final double totalSales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7D8D1), Color(0xFFD2B8AE)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: darkBrown.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.55),
            child: Text(
              name.isEmpty ? '—' : name.substring(0, 1),
              style: const TextStyle(color: darkBrown, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'お名前未設定' : name,
            style: const TextStyle(color: darkBrown, fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _Stat(label: '来店回数', value: '$visitCount回')),
              Container(width: 1, height: 38, color: Colors.white.withOpacity(0.55)),
              Expanded(child: _Stat(label: '累計売上', value: '¥${_formatAmount(totalSales)}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: darkBrown.withOpacity(0.65), fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(color: darkBrown, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: darkBrown.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: darkBrown),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(color: darkBrown, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _CustomerTextField extends StatelessWidget {
  const _CustomerTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: primaryColor.withOpacity(0.09),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: darkBrown),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.isSaving, required this.onPressed});
  final String label;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: darkBrown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CustomerSaleCard extends StatelessWidget {
  const _CustomerSaleCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rawDate = data['date'];
    final date = rawDate is Timestamp ? rawDate.toDate() : null;
    final price = data['price'];
    final menu = data['menu'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.spa_outlined, color: darkBrown, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu?.trim().isNotEmpty == true ? menu! : 'メニュー未設定',
                  style: const TextStyle(color: darkBrown, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null ? '日付未設定' : '${date.year}年${date.month}月${date.day}日',
                  style: const TextStyle(color: _mutedBrown, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '¥${_formatAmount(price is num ? price.toDouble() : 0)}',
            style: const TextStyle(color: darkBrown, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _NoCustomerSales extends StatelessWidget {
  const _NoCustomerSales();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: _mutedBrown, size: 34),
          SizedBox(height: 10),
          Text('この顧客の売上履歴はありません', style: TextStyle(color: _mutedBrown)),
        ],
      ),
    );
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(radius: 14),
          SizedBox(height: 14),
          Text('カルテを読み込んでいます', style: TextStyle(color: _mutedBrown)),
        ],
      ),
    );
  }
}

class _DetailNotFoundState extends StatelessWidget {
  const _DetailNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, color: _mutedBrown, size: 48),
            SizedBox(height: 16),
            Text(
              '顧客データが見つかりません',
              style: TextStyle(color: darkBrown, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 7),
            Text('削除されたか、参照できない顧客です。', style: TextStyle(color: _mutedBrown)),
          ],
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final permissionDenied = error is FirebaseException &&
        (error as FirebaseException).code == 'permission-denied';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _mutedBrown, size: 50),
            const SizedBox(height: 16),
            const Text(
              'カルテを読み込めませんでした',
              style: TextStyle(color: darkBrown, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              permissionDenied
                  ? 'この店舗の顧客データを表示する権限がありません。'
                  : '通信環境を確認して、もう一度お試しください。',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedBrown),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(double value) {
  return value.round().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );
}
