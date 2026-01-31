import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> with TickerProviderStateMixin {
  final controller = TextEditingController();
  final List<int> quickAmounts = [50000, 100000, 200000, 500000];
  double? selectedAmount;
  late TabController _tabController;
  bool isSubmitting = false;
  List<dynamic> history = [];
  bool historyLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nạp tiền'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Admin xác nhận'),
            Tab(text: 'Quét QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _manualTopUp(),
          _qrTopUp(),
        ],
      ),
    );
  }

  Widget _manualTopUp() {
    final auth = Provider.of<AuthProvider>(context);
    final balance = auth.walletBalance ?? 0;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Color(0xFF16A34A), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư ví',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${balance.toStringAsFixed(0)} VNĐ',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text('Chọn nhanh số tiền', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: quickAmounts
                  .map(
                    (amt) => ChoiceChip(
                      label: Text('${amt ~/ 1000}K'),
                      selected: selectedAmount == amt,
                      onSelected: (_) => _setAmount(amt.toDouble()),
                      selectedColor: const Color(0xFF16A34A).withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: selectedAmount == amt ? const Color(0xFF0F172A) : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tiền cần nạp (VNĐ)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value);
                    setState(() {
                      selectedAmount = amount;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: Text(isSubmitting ? 'Đang gửi yêu cầu...' : 'Gửi yêu cầu nạp (Admin xác nhận)'),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amount = double.tryParse(controller.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
                          );
                          return;
                        }

                        setState(() => isSubmitting = true);
                        try {
                          await Provider.of<AuthProvider>(context, listen: false).requestTopUp(amount);
                          if (!mounted) return;
                          await _loadHistory();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã gửi yêu cầu nạp ${amount.toStringAsFixed(0)} VNĐ, chờ admin xác nhận.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _historySection(),
          ],
        ),
      ),
    );
  }

  Widget _qrTopUp() {
    final amount = double.tryParse(controller.text) ?? 0;
    final qrData = amount > 0 ? 'NAPTIEN:$amount:USER:${Provider.of<AuthProvider>(context).fullName}' : 'NAPTIEN:0';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Số tiền cần nạp (VNĐ)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() {
                    selectedAmount = double.tryParse(value);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (amount > 0) ...[
              const Text(
                'Quét mã QR để thanh toán ngay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 220,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Đã thanh toán'),
                  onPressed: () async {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).topUp(amount);

                    if (!mounted) return;
                    await _loadHistory();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nạp tiền thành công!')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Vui lòng nhập số tiền trước',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 24),
            _historySection(),
          ],
        ),
      ),
    );
  }

  Widget _historySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử giao dịch', style: TextStyle(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: historyLoading ? null : _loadHistory,
                  child: historyLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Tải lại'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (history.isEmpty && !historyLoading)
              const Text('Chưa có giao dịch', style: TextStyle(color: Colors.grey)),
            if (historyLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (history.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                  final type = (item['type'] ?? '').toString();
                  final description = (item['description'] ?? '').toString();
                  final created = DateTime.tryParse(item['createdDate']?.toString() ?? '');
                  final isPositive = amount >= 0;
                  return ListTile(
                    leading: Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    title: Text('${amount.toStringAsFixed(0)} VNĐ'),
                    subtitle: Text(
                      '${type.isNotEmpty ? type : 'Giao dịch'} · ${created != null ? created.toLocal() : ''}\n${description.isNotEmpty ? description : ''}',
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: history.length,
              ),
          ],
        ),
      ),
    );
  }

  void _setAmount(double amount) {
    setState(() {
      selectedAmount = amount;
      controller.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _loadHistory() async {
    setState(() => historyLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');
      if (token == null) return;
      final data = await auth.api.getWalletHistory(token);
      if (!mounted) return;
      setState(() {
        history = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được lịch sử: $e')),
      );
    } finally {
      if (mounted) setState(() => historyLoading = false);
    }
  }
}
