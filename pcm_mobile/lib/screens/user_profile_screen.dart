import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List bookings = [];
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

      final profileData = await auth.api.getProfile(token!);
      final bookingsData = await auth.api.getMyBookings(token);

      setState(() {
        profile = profileData;
        bookings = bookingsData;
      });
    } catch (e) {
      debugPrint('Load data failed: $e');
    } finally {
      setState(() {
        loading = false;
      });
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
    final totalSpent = bookings.fold(0.0, (sum, b) => sum + (b['totalPrice'] as num));
    final tier = profile?['tier'] ?? 'Standard';

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.lightGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile?['fullName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tier: $tier',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.lightGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.book_online, color: Colors.lightGreen),
                          const SizedBox(height: 8),
                          Text(
                            '$totalBookings',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Sân đã đặt'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.lightGreen),
                          const SizedBox(height: 8),
                          Text(
                            '${totalSpent.toStringAsFixed(0)} VNĐ',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Tổng chi tiêu'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.lightGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Số dư ví: ${profile?['walletBalance'] ?? 0} VNĐ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Đổi mật khẩu'),
                onPressed: () => _showChangePasswordDialog(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                validator: (value) {
                  if (value != newPasswordCtrl.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await auth.changePassword(
                  currentPasswordCtrl.text,
                  newPasswordCtrl.text,
                );

                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đổi mật khẩu thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đổi mật khẩu thất bại')),
                  );
                }
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }
}