import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';
import 'topup_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List bookings = [];
  List walletHistory = [];
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = await auth.storage.read(key: 'token');

      final results = await Future.wait([
        auth.api.getProfile(token!),
        auth.api.getMyBookings(token),
        auth.api.getWalletHistory(token),
      ]);

      setState(() {
        profile = results[0] as Map<String, dynamic>;
        bookings = results[1] as List;
        walletHistory = results[2] as List;
      });
    } catch (e) {
      debugPrint('Load data failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalBookings = bookings.length;
    final totalSpent = bookings.fold<double>(0.0, (sum, b) => sum + ((b['totalPrice'] as num?)?.toDouble() ?? 0));
    final totalTopUp = _topUpHistory().fold<double>(0.0, (sum, h) => sum + ((h['amount'] as num?)?.toDouble() ?? 0));
    final tier = profile?['tier'] ?? 'Hội viên';
    final rank = _rankFromSpent(totalSpent);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _profileHeader(tier, rank),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _statCard('Tổng nạp', _formatCurrency(totalTopUp), Icons.savings_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Tổng chi tiêu', _formatCurrency(totalSpent), Icons.attach_money)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Sân đã đặt', '$totalBookings', Icons.book_online)),
                  ],
                ),
                const SizedBox(height: 14),
                _walletCard(),
                const SizedBox(height: 14),
                _recentTopUps(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(String tier, Map<String, dynamic> rank) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, color: Color(0xFF16A34A), size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['fullName'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tier $tier',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rank['name'] as String,
                            style: TextStyle(
                              color: rank['color'] as Color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Icon(
                  themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tên đăng nhập: ${profile?['userName'] ?? '--'}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF16A34A)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _walletCard() {
    final balance = profile?['walletBalance'] ?? 0;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF16A34A), size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Số dư ví', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency((balance as num).toDouble()),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nạp'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TopUpScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTopUps() {
    final recent = _topUpHistory().take(5).toList();
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
                const Text('Top-up gần đây', style: TextStyle(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: loadData,
                  child: const Text('Tải lại'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Text('Chưa có giao dịch nạp', style: TextStyle(color: Colors.grey)),
            if (recent.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = recent[index];
                  final amount = (item['amount'] as num?)?.toDouble() ?? 0;
                  final type = (item['type'] ?? '').toString();
                  final created = DateTime.tryParse(item['createdDate']?.toString() ?? '');
                  final description = (item['description'] ?? '').toString();
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.savings, color: Color(0xFF16A34A)),
                    ),
                    title: Text(_formatCurrency(amount)),
                    subtitle: Text(
                      '${type.isNotEmpty ? type : 'Top-up'} · ${created != null ? created.toLocal() : ''}\n${description.isNotEmpty ? description : ''}',
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: recent.length,
              ),
          ],
        ),
      ),
    );
  }

  Iterable<Map<String, dynamic>> _topUpHistory() {
    return walletHistory.where((h) {
      if (h is! Map) return false;
      final type = (h['type'] ?? '').toString().toLowerCase();
      return type.contains('topup');
    }).map((h) => Map<String, dynamic>.from(h as Map));
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(0)} VNĐ';
  }

  Map<String, dynamic> _rankFromSpent(double spent) {
    if (spent >= 3000000) {
      return {'name': 'Elite', 'color': const Color(0xFFEF4444)};
    }
    if (spent >= 1500000) {
      return {'name': 'Pro', 'color': const Color(0xFF0EA5E9)};
    }
    if (spent >= 500000) {
      return {'name': 'Member', 'color': const Color(0xFF16A34A)};
    }
    return {'name': 'Newbie', 'color': const Color(0xFF94A3B8)};
  }
}